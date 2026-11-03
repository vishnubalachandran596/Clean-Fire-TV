#include "CleanHomeShell.h"

#include <apmf/apmf_base.h>
#include <apmf/array.h>
#include <apmf/fixed_array.h>
#include <apmf/iface/com/amazon/apmf/IProcess.h>
#include <apmf/iface/com/amazon/apmf/InvalidArgumentError.h>
#include <apmf/iface/com/amazon/kepler/tasks/IKeplerTasksModule.h>
#include <apmf/iface/com/amazon/kepler/tasks/ITaskManager.h>
#include <apmf/iface/com/amazon/kepler/tasks/ITaskRegistration.h>
#include <apmf/iface/com/amazon/kepler/tasks/ITaskRequest.h>
#include <apmf/iface/com/amazon/kepler/tasks/ITaskRequestBuilder.h>
#include <apmf/iface/com/amazon/kepler/tasks/ITimeProperties.h>
#include <apmf/iface/com/amazon/kepler/tasks/ITimePropertiesBuilder.h>
#include <apmf/iface/com/amazon/kepler/tasks/TaskNameExistsError.h>
#include <apmf/process.h>
#include <apmf/ptr.h>

#include <arpa/inet.h>
#include <cstdlib>
#include <cstring>
#include <netinet/in.h>
#include <string>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>
#include <vector>

using namespace com::amazon::kepler::turbomodule;
using apmf::GetProcessObject;
using apmf::Ptr;
namespace iApmf = apmf::iface::com::amazon::apmf;
namespace kTasks = apmf::iface::com::amazon::kepler::tasks;

namespace CleanHomeShellTurboModule {
namespace {

constexpr const char* kEnsureScript = "/data/ensure-services.sh";
constexpr const char* kStartBooster = "/data/start-booster.sh";
constexpr const char* kBootComponentId = "com.cleanhome.launcher.boot";
constexpr const char* kBootTaskName = "cleanhome-boot-ensure";
constexpr int64_t kBootRepeatSeconds = 120;

// ADB wire protocol (little-endian commands as on-wire LE uint32).
constexpr uint32_t kAdbCnxn = 0x4e584e43; // CNXN
constexpr uint32_t kAdbOpen = 0x4e45504f; // OPEN
constexpr uint32_t kAdbClse = 0x45534c43; // CLSE
constexpr uint32_t kAdbOkay = 0x59414b4f; // OKAY
constexpr uint32_t kAdbWrte = 0x45545257; // WRTE

bool fileExecutable(const char* path) {
  struct stat st {};
  return ::stat(path, &st) == 0 && (st.st_mode & S_IXUSR);
}

int runShellSystem(const std::string& command) {
  const int status = ::system(command.c_str());
  if (status < 0) {
    return -1;
  }
  if (WIFEXITED(status)) {
    return WEXITSTATUS(status);
  }
  return -2;
}

uint32_t adbSum(const uint8_t* data, uint32_t len) {
  uint32_t sum = 0;
  for (uint32_t i = 0; i < len; ++i) {
    sum += data[i];
  }
  return sum;
}

bool writeAll(int fd, const void* buf, size_t len) {
  const uint8_t* p = static_cast<const uint8_t*>(buf);
  size_t off = 0;
  while (off < len) {
    const ssize_t n = ::write(fd, p + off, len - off);
    if (n <= 0) {
      return false;
    }
    off += static_cast<size_t>(n);
  }
  return true;
}

bool readAll(int fd, void* buf, size_t len) {
  uint8_t* p = static_cast<uint8_t*>(buf);
  size_t off = 0;
  while (off < len) {
    const ssize_t n = ::read(fd, p + off, len - off);
    if (n <= 0) {
      return false;
    }
    off += static_cast<size_t>(n);
  }
  return true;
}

bool sendAdbMessage(
    int fd,
    uint32_t command,
    uint32_t arg0,
    uint32_t arg1,
    const void* payload,
    uint32_t payloadLen) {
  uint8_t header[24];
  auto put = [&](int idx, uint32_t v) {
    header[idx] = static_cast<uint8_t>(v & 0xff);
    header[idx + 1] = static_cast<uint8_t>((v >> 8) & 0xff);
    header[idx + 2] = static_cast<uint8_t>((v >> 16) & 0xff);
    header[idx + 3] = static_cast<uint8_t>((v >> 24) & 0xff);
  };
  put(0, command);
  put(4, arg0);
  put(8, arg1);
  put(12, payloadLen);
  put(16, payload ? adbSum(static_cast<const uint8_t*>(payload), payloadLen) : 0);
  put(20, command ^ 0xffffffffu);
  if (!writeAll(fd, header, sizeof(header))) {
    return false;
  }
  if (payloadLen > 0 && payload != nullptr) {
    return writeAll(fd, payload, payloadLen);
  }
  return true;
}

bool recvAdbMessage(
    int fd,
    uint32_t& command,
    uint32_t& arg0,
    uint32_t& arg1,
    std::vector<uint8_t>& payload) {
  uint8_t header[24];
  if (!readAll(fd, header, sizeof(header))) {
    return false;
  }
  auto get = [&](int idx) -> uint32_t {
    return static_cast<uint32_t>(header[idx]) |
           (static_cast<uint32_t>(header[idx + 1]) << 8) |
           (static_cast<uint32_t>(header[idx + 2]) << 16) |
           (static_cast<uint32_t>(header[idx + 3]) << 24);
  };
  command = get(0);
  arg0 = get(4);
  arg1 = get(8);
  const uint32_t len = get(12);
  payload.assign(len, 0);
  if (len > 0 && !readAll(fd, payload.data(), len)) {
    return false;
  }
  return true;
}

/**
 * Run a shell command via local unauthenticated ADB (vdad on :5555).
 * Lands in com.amazon.dev.shell with the same privileges as Mac adb shell —
 * needed because package sandboxes may not be able to setsid/vlcm the same way.
 */
std::string runViaLocalAdb(const std::string& shellCommand) {
  const int fd = ::socket(AF_INET, SOCK_STREAM, 0);
  if (fd < 0) {
    return "adb-socket-fail";
  }

  sockaddr_in addr {};
  addr.sin_family = AF_INET;
  addr.sin_port = htons(5555);
  addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);

  if (::connect(fd, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) != 0) {
    ::close(fd);
    return "adb-connect-fail";
  }

  // CNXN system -> host banner
  const char* banner = "host::\0";
  if (!sendAdbMessage(fd, kAdbCnxn, 0x01000001, 4096, banner, 7)) {
    ::close(fd);
    return "adb-cnxn-send-fail";
  }

  uint32_t cmd = 0, a0 = 0, a1 = 0;
  std::vector<uint8_t> payload;
  if (!recvAdbMessage(fd, cmd, a0, a1, payload) || cmd != kAdbCnxn) {
    ::close(fd);
    return "adb-cnxn-recv-fail";
  }

  std::string openPayload = "shell:" + shellCommand;
  openPayload.push_back('\0');
  const uint32_t localId = 1;
  if (!sendAdbMessage(
          fd,
          kAdbOpen,
          localId,
          0,
          openPayload.data(),
          static_cast<uint32_t>(openPayload.size()))) {
    ::close(fd);
    return "adb-open-send-fail";
  }

  // Drain until CLSE (or timeout via short loop).
  for (int i = 0; i < 40; ++i) {
    if (!recvAdbMessage(fd, cmd, a0, a1, payload)) {
      break;
    }
    if (cmd == kAdbOkay) {
      continue;
    }
    if (cmd == kAdbWrte) {
      // ACK writes
      sendAdbMessage(fd, kAdbOkay, localId, a0, nullptr, 0);
      continue;
    }
    if (cmd == kAdbClse) {
      break;
    }
  }

  ::close(fd);
  return "adb-ok:" + shellCommand;
}

std::string buildEnsureCommand(bool noLaunch) {
  if (!fileExecutable(kEnsureScript) && !fileExecutable(kStartBooster)) {
    // Still try ADB path — host /data may differ from package view of /data.
    if (noLaunch) {
      return "sh /data/ensure-services.sh --no-launch";
    }
    return "sh /data/ensure-services.sh";
  }
  if (fileExecutable(kEnsureScript)) {
    std::string cmd = "sh ";
    cmd += kEnsureScript;
    if (noLaunch) {
      cmd += " --no-launch";
    }
    return cmd;
  }
  return std::string("sh ") + kStartBooster;
}

std::string ensureServicesImpl(bool noLaunch) {
  const std::string cmd = buildEnsureCommand(noLaunch);
  // Prefer local ADB so the work runs with developer-shell privileges.
  const std::string adbResult = runViaLocalAdb(cmd + " >/data/cleanhome-ensure.log 2>&1");
  if (adbResult.rfind("adb-ok:", 0) == 0) {
    return adbResult;
  }
  // Fallback: direct system() in-process (may be sandboxed).
  const int rc = runShellSystem(cmd + " >/data/cleanhome-ensure.log 2>&1");
  if (rc == 0) {
    return "system-ok:" + cmd + " | adb-fallback:" + adbResult;
  }
  return "fail:rc=" + std::to_string(rc) + " adb=" + adbResult + " cmd=" + cmd;
}

std::string scheduleBootTaskImpl() {
  try {
    Ptr<iApmf::IProcess> proc = GetProcessObject();
    Ptr<kTasks::IKeplerTasksModule> ktModule =
        proc->getComponent("/com.amazon.kepler.tasks.tasks_module")
            .QueryInterface<kTasks::IKeplerTasksModule>();

    Ptr<kTasks::ITaskManager> taskManager = ktModule->makeTaskManager();
    Ptr<kTasks::ITaskRequestBuilder> requestBuilder = ktModule->makeTaskRequestBuilder();
    Ptr<kTasks::ITimePropertiesBuilder> timeBuilder = ktModule->makeTimePropertiesBuilder();

    iApmf::MonotonicDuration repeat{};
    repeat.time.seconds = kBootRepeatSeconds;
    Ptr<kTasks::ITimeProperties> timeProperties = timeBuilder->repeatInterval(repeat)->build();

    Ptr<kTasks::ITaskRequest> request =
        requestBuilder->requireTime(timeProperties)
            ->repeating()
            ->persistAfterAppDeath()
            ->name(kBootTaskName)
            ->build(kBootComponentId);

    try {
      taskManager->submit(request);
      return std::string("scheduled:") + kBootTaskName;
    } catch (const kTasks::TaskNameExistsError&) {
      return std::string("already-scheduled:") + kBootTaskName;
    }
  } catch (const std::exception& e) {
    return std::string("schedule-error:") + e.what();
  } catch (...) {
    return "schedule-error:unknown";
  }
}

} // namespace

CleanHomeShell::CleanHomeShell() {}
CleanHomeShell::~CleanHomeShell() noexcept {}

Promise CleanHomeShell::ensureServices(double noLaunch) {
  const bool skipLaunch = noLaunch != 0.0;
  return Promise([skipLaunch](std::shared_ptr<Promise> promise) {
    try {
      promise->resolve(ensureServicesImpl(skipLaunch));
    } catch (const std::exception& e) {
      promise->reject(std::string(e.what()));
    }
  });
}

Promise CleanHomeShell::scheduleBootTask() {
  return Promise([](std::shared_ptr<Promise> promise) {
    try {
      promise->resolve(scheduleBootTaskImpl());
    } catch (const std::exception& e) {
      promise->reject(std::string(e.what()));
    }
  });
}

Promise CleanHomeShell::bootOnce(double noLaunch) {
  const bool skipLaunch = noLaunch != 0.0;
  return Promise([skipLaunch](std::shared_ptr<Promise> promise) {
    try {
      const std::string ensure = ensureServicesImpl(skipLaunch);
      const std::string schedule = scheduleBootTaskImpl();
      promise->resolve(ensure + " | " + schedule);
    } catch (const std::exception& e) {
      promise->reject(std::string(e.what()));
    }
  });
}

} // namespace CleanHomeShellTurboModule
