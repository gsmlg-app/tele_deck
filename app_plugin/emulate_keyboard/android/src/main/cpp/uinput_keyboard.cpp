#include <jni.h>
#include <android/log.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <cstdio>
#include <linux/uinput.h>
#include <linux/input.h>

#define LOG_TAG "UInputKeyboard"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)

// Global file descriptor for uinput device
static int uinput_fd = -1;

/**
 * Emit an input event through uinput.
 */
static int emit_event(int type, int code, int value) {
    if (uinput_fd < 0) {
        LOGE("uinput device not initialized");
        return -1;
    }

    struct input_event ev;
    memset(&ev, 0, sizeof(ev));
    gettimeofday(&ev.time, NULL);
    ev.type = type;
    ev.code = code;
    ev.value = value;

    if (write(uinput_fd, &ev, sizeof(ev)) != sizeof(ev)) {
        LOGE("Failed to write event: %s", strerror(errno));
        return -1;
    }
    return 0;
}

/**
 * Send a sync event to finalize input.
 */
static int emit_sync() {
    return emit_event(EV_SYN, SYN_REPORT, 0);
}

extern "C" {

JNIEXPORT jboolean JNICALL
Java_app_gsmlg_emulate_1keyboard_UInputBackend_nativeIsAvailable(JNIEnv *env, jobject thiz) {
    // Check if uinput device exists
    if (access("/dev/uinput", F_OK) == 0) {
        return JNI_TRUE;
    }
    if (access("/dev/input/uinput", F_OK) == 0) {
        return JNI_TRUE;
    }
    return JNI_FALSE;
}

JNIEXPORT jboolean JNICALL
Java_app_gsmlg_emulate_1keyboard_UInputBackend_nativeIsConnected(JNIEnv *env, jobject thiz) {
    return uinput_fd >= 0 ? JNI_TRUE : JNI_FALSE;
}

JNIEXPORT jboolean JNICALL
Java_app_gsmlg_emulate_1keyboard_UInputBackend_nativeInitialize(JNIEnv *env, jobject thiz) {
    LOGI("Initializing uinput keyboard device");

    // Try to open uinput device
    const char* uinput_paths[] = {"/dev/uinput", "/dev/input/uinput", NULL};

    for (int i = 0; uinput_paths[i] != NULL; i++) {
        uinput_fd = open(uinput_paths[i], O_WRONLY | O_NONBLOCK);
        if (uinput_fd >= 0) {
            LOGI("Opened uinput at %s", uinput_paths[i]);
            break;
        }
    }

    if (uinput_fd < 0) {
        LOGE("Failed to open uinput device: %s", strerror(errno));
        return JNI_FALSE;
    }

    // Enable key events
    if (ioctl(uinput_fd, UI_SET_EVBIT, EV_KEY) < 0) {
        LOGE("Failed to set EV_KEY: %s", strerror(errno));
        close(uinput_fd);
        uinput_fd = -1;
        return JNI_FALSE;
    }

    // Enable all key codes we might use (0-255 covers most keys)
    for (int i = 0; i < 256; i++) {
        ioctl(uinput_fd, UI_SET_KEYBIT, i);
    }

    // Enable synchronization events
    if (ioctl(uinput_fd, UI_SET_EVBIT, EV_SYN) < 0) {
        LOGE("Failed to set EV_SYN: %s", strerror(errno));
        close(uinput_fd);
        uinput_fd = -1;
        return JNI_FALSE;
    }

    // Configure the virtual device
    struct uinput_user_dev uidev;
    memset(&uidev, 0, sizeof(uidev));
    snprintf(uidev.name, UINPUT_MAX_NAME_SIZE, "TeleDeck Virtual Keyboard");
    uidev.id.bustype = BUS_USB;
    uidev.id.vendor = 0x1234;
    uidev.id.product = 0x5678;
    uidev.id.version = 1;

    if (write(uinput_fd, &uidev, sizeof(uidev)) != sizeof(uidev)) {
        LOGE("Failed to write device info: %s", strerror(errno));
        close(uinput_fd);
        uinput_fd = -1;
        return JNI_FALSE;
    }

    // Create the device
    if (ioctl(uinput_fd, UI_DEV_CREATE) < 0) {
        LOGE("Failed to create device: %s", strerror(errno));
        close(uinput_fd);
        uinput_fd = -1;
        return JNI_FALSE;
    }

    LOGI("uinput keyboard device created successfully");

    // Give the system time to register the device
    usleep(100000); // 100ms

    return JNI_TRUE;
}

JNIEXPORT void JNICALL
Java_app_gsmlg_emulate_1keyboard_UInputBackend_nativeCleanup(JNIEnv *env, jobject thiz) {
    LOGI("Cleaning up uinput device");

    if (uinput_fd >= 0) {
        ioctl(uinput_fd, UI_DEV_DESTROY);
        close(uinput_fd);
        uinput_fd = -1;
    }
}

JNIEXPORT void JNICALL
Java_app_gsmlg_emulate_1keyboard_UInputBackend_nativeSendKeyDown(JNIEnv *env, jobject thiz, jint key_code) {
    LOGD("Key down: %d", key_code);
    emit_event(EV_KEY, key_code, 1); // 1 = key down
    emit_sync();
}

JNIEXPORT void JNICALL
Java_app_gsmlg_emulate_1keyboard_UInputBackend_nativeSendKeyUp(JNIEnv *env, jobject thiz, jint key_code) {
    LOGD("Key up: %d", key_code);
    emit_event(EV_KEY, key_code, 0); // 0 = key up
    emit_sync();
}

} // extern "C"
