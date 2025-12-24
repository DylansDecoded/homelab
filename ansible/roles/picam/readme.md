# Raspberry Pi Zero IP Camera Complete Setup Guide
## Using OV5647 5MP Camera Module for 720p Continuous Recording

---

## Hardware Requirements

- **Raspberry Pi Zero W or Zero 2 W** (WiFi/Ethernet connectivity required)
- **OV5647 5MP Camera Module** with appropriate ribbon cable
- **MicroSD Card** (16GB minimum, 32GB+ recommended)
- **Power Supply** (5V 2A recommended)
- **Optional:** Case, heatsink for Zero 2W

---

## Initial Setup (Common to All Options)

### 1. Flash Raspberry Pi OS

```bash
# Download Raspberry Pi OS Lite (Bookworm)
# Use Raspberry Pi Imager: https://www.raspberrypi.com/software/

# During imaging, configure:
# - Hostname: ipcam (or your choice)
# - Enable SSH
# - Configure WiFi credentials
# - Set username/password
```

### 2. First Boot Configuration

```bash
# SSH into your Pi
ssh pi@ipcam.local

# Update system
sudo apt update && sudo apt upgrade -y

# Install essential tools
sudo apt install -y git vim screen htop

# Verify camera connection
libcamera-hello --list-cameras

# Expected output should show:
# 0 : ov5647 [2592x1944] (/base/soc/i2c0mux/i2c@1/ov5647@36)
```

### 3. Configure /boot/firmware/config.txt

```bash
sudo nano /boot/firmware/config.txt

# Add/verify these settings:
camera_auto_detect=1
dtoverlay=vc4-kms-v3d
gpu_mem=256
disable_camera_led=1

# Save and reboot
sudo reboot
```

---

## OPTION 1: MotionEyeOS (Deprecated but Functional)

### Installation

```bash
# Download MotionEyeOS image
wget https://github.com/motioneye-project/motioneyeos/releases/download/20200606/motioneyeos-raspberrypi-20200606.img.gz

# Flash to SD card using Raspberry Pi Imager or dd

# Default credentials:
# Username: admin
# Password: (blank)

# Access web interface:
# http://ipcam-ip-address:8765
```

### Configuration

1. **Network Setup:**
   - Configure WiFi via web interface
   - Set static IP if desired

2. **Video Settings:**
   - Resolution: 1280x720
   - Frame Rate: 25 fps
   - Video Streaming: Enable
   - Video Streaming Port: 8081

3. **Motion Detection:**
   - Enable motion detection
   - Configure sensitivity
   - Set recording path (local or network)

4. **Access Streams:**
   - MJPEG: `http://<ip>:8081`
   - Snapshot: `http://<ip>:8765/picture/1/current/`

**WARNING:** MotionEyeOS is no longer maintained. Consider other options for production use.

---

## OPTION 2: Motion with Web Interface

### Installation

```bash
# Install Motion
sudo apt install -y motion

# Create motion config directory
sudo mkdir -p /etc/motion
sudo chown motion:motion /var/lib/motion
```

### Configuration

```bash
sudo nano /etc/motion/motion.conf

# Key settings to modify:
daemon on
width 1280
height 720
framerate 25
stream_port 8081
stream_localhost off
stream_quality 85
stream_maxrate 25

# Enable web control
webcontrol_port 8080
webcontrol_localhost off

# Motion detection
threshold 1500
minimum_motion_frames 1

# Output settings
output_pictures off
ffmpeg_output_movies on
ffmpeg_video_codec h264_v4l2m2m

# Storage location
target_dir /home/pi/motion_videos
```

### Enable and Start Service

```bash
# Enable motion to run as daemon
sudo nano /etc/default/motion
# Set: start_motion_daemon=yes

# Start motion service
sudo systemctl enable motion
sudo systemctl start motion

# Check status
sudo systemctl status motion
```

### Access

- **Live Stream:** `http://<ip>:8081`
- **Web Control:** `http://<ip>:8080`

### Performance Note

Motion uses software encoding, resulting in high CPU usage (50-80%) on Pi Zero. Best for low frame rate applications or Pi Zero 2W.

---

## OPTION 3: libcamera-vid + v4l2rtspserver (RECOMMENDED)

This is the best option for 720p continuous streaming with hardware acceleration.

### Installation

```bash
# Install dependencies
sudo apt install -y git cmake liblog4cpp5-dev libv4l-dev

# Clone and build v4l2rtspserver
cd ~
git clone https://github.com/mpromonet/v4l2rtspserver.git
cd v4l2rtspserver
cmake .
make
sudo make install

# Verify installation
which v4l2rtspserver
```

### Method A: Using v4l2rtspserver directly

```bash
# Load v4l2 driver for libcamera
sudo modprobe bcm2835-v4l2

# Make it load on boot
echo "bcm2835-v4l2" | sudo tee -a /etc/modules

# Start RTSP server
v4l2rtspserver -W 1280 -H 720 -F 25 -P 8554 /dev/video0 &

# Stream URL: rtsp://<ip>:8554/unicast
```

### Method B: Using libcamera-vid + mediamtx (Modern Approach)

```bash
# Download mediamtx (formerly rtsp-simple-server)
cd ~
wget https://github.com/bluenviron/mediamtx/releases/download/v1.9.0/mediamtx_v1.9.0_linux_arm64v8.tar.gz
tar -xzf mediamtx_v1.9.0_linux_arm64v8.tar.gz

# For Pi Zero (arm32):
wget https://github.com/bluenviron/mediamtx/releases/download/v1.9.0/mediamtx_v1.9.0_linux_armv7.tar.gz
tar -xzf mediamtx_v1.9.0_linux_armv7.tar.gz

# Start mediamtx server
./mediamtx &

# Create streaming script
nano ~/stream_camera.sh
```

```bash
#!/bin/bash
# stream_camera.sh

# Stream to mediamtx
libcamera-vid -t 0 \
  --width 1280 \
  --height 720 \
  --framerate 25 \
  --bitrate 2000000 \
  --inline \
  --codec h264 \
  --listen \
  -o - | ffmpeg -re -i - -c:v copy -f rtsp rtsp://localhost:8554/camera
```

```bash
chmod +x ~/stream_camera.sh
./stream_camera.sh
```

### Method C: libcamera-vid + VLC (Simplest for Testing)

```bash
# Install VLC
sudo apt install -y vlc-bin vlc-plugin-base

# Stream with VLC
libcamera-vid -t 0 \
  --width 1280 \
  --height 720 \
  --framerate 25 \
  --inline \
  --codec h264 \
  -o - | cvlc stream:///dev/stdin \
  --sout '#rtp{sdp=rtsp://:8554/stream}' \
  :demux=h264
```

### Create Systemd Service (Auto-start on Boot)

```bash
sudo nano /etc/systemd/system/ipcamera.service
```

```ini
[Unit]
Description=IP Camera RTSP Stream
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi
ExecStart=/usr/bin/libcamera-vid -t 0 --width 1280 --height 720 --framerate 25 --bitrate 2500000 --inline --codec h264 -o - | /usr/bin/cvlc stream:///dev/stdin --sout '#rtp{sdp=rtsp://:8554/stream}' :demux=h264
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable ipcamera.service
sudo systemctl start ipcamera.service
sudo systemctl status ipcamera.service
```

### Accessing the Stream

```bash
# View with VLC on another device
vlc rtsp://<raspberry-pi-ip>:8554/stream

# View with ffplay
ffplay rtsp://<raspberry-pi-ip>:8554/stream

# Integrate with NVR software (Blue Iris, Frigate, etc.)
# Use RTSP URL: rtsp://<ip>:8554/stream
```

### Performance Optimization

```bash
# Optimal settings for Pi Zero W (single core)
libcamera-vid -t 0 \
  --width 1280 \
  --height 720 \
  --framerate 25 \
  --bitrate 2000000 \
  --inline \
  --codec h264 \
  --level 4.2 \
  --intra 50 \
  -o -

# For Pi Zero 2W (quad core) - can push higher
libcamera-vid -t 0 \
  --width 1280 \
  --height 720 \
  --framerate 30 \
  --bitrate 3000000 \
  --inline \
  --codec h264 \
  --level 4.2 \
  --intra 60 \
  -o -
```

**CPU Usage:** ~10-15% (hardware accelerated)

---

## OPTION 4: Picamera2 + Custom Python Web Interface

### Installation

```bash
# Install picamera2 and dependencies
sudo apt install -y python3-picamera2 python3-flask python3-opencv

# Install additional Python packages
pip3 install flask flask-cors
```

### Create Flask Web Application

```bash
mkdir ~/ipcamera
cd ~/ipcamera
nano camera_server.py
```

```python
#!/usr/bin/env python3
"""
Raspberry Pi Zero IP Camera with Web Interface
Uses Picamera2 for modern camera control
"""

from flask import Flask, Response, render_template_string
from picamera2 import Picamera2
from picamera2.encoders import H264Encoder
from picamera2.outputs import FileOutput
import io
import time
import threading

app = Flask(__name__)

# Global camera instance
picam2 = None
output_stream = None

class StreamingOutput(io.BufferedIOBase):
    def __init__(self):
        self.frame = None
        self.condition = threading.Condition()

    def write(self, buf):
        with self.condition:
            self.frame = buf
            self.condition.notify_all()

def initialize_camera():
    global picam2, output_stream
    
    picam2 = Picamera2()
    
    # Configure for 720p video
    video_config = picam2.create_video_configuration(
        main={
            "size": (1280, 720),
            "format": "RGB888"
        },
        encode="main",
        buffer_count=4
    )
    
    picam2.configure(video_config)
    
    output_stream = StreamingOutput()
    encoder = H264Encoder(bitrate=2000000, repeat=True)
    picam2.start_recording(encoder, FileOutput(output_stream))

def generate_frames():
    """Generator function for MJPEG stream"""
    global output_stream
    
    while True:
        with output_stream.condition:
            output_stream.condition.wait()
            frame = output_stream.frame
        
        yield (b'--frame\r\n'
               b'Content-Type: image/jpeg\r\n\r\n' + frame + b'\r\n')

HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>Pi Camera Stream</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #1a1a1a;
            color: #fff;
        }
        .container {
            max-width: 1280px;
            margin: 0 auto;
        }
        h1 {
            text-align: center;
            color: #4CAF50;
        }
        .video-container {
            text-align: center;
            margin: 20px 0;
        }
        img {
            max-width: 100%;
            border: 2px solid #4CAF50;
            border-radius: 8px;
        }
        .controls {
            text-align: center;
            margin: 20px 0;
        }
        button {
            background-color: #4CAF50;
            color: white;
            padding: 10px 20px;
            margin: 5px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 16px;
        }
        button:hover {
            background-color: #45a049;
        }
        .info {
            background-color: #2a2a2a;
            padding: 15px;
            border-radius: 8px;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎥 Raspberry Pi Zero IP Camera</h1>
        <div class="info">
            <p><strong>Resolution:</strong> 1280x720 (720p)</p>
            <p><strong>Frame Rate:</strong> 25 FPS</p>
            <p><strong>Codec:</strong> H.264</p>
            <p><strong>Status:</strong> <span style="color: #4CAF50;">● Live</span></p>
        </div>
        <div class="video-container">
            <img src="{{ url_for('video_feed') }}" alt="Camera Stream">
        </div>
        <div class="controls">
            <button onclick="window.location.reload()">Refresh Stream</button>
            <button onclick="takeSnapshot()">Take Snapshot</button>
        </div>
    </div>
    
    <script>
        function takeSnapshot() {
            fetch('/snapshot')
                .then(response => response.blob())
                .then(blob => {
                    const url = window.URL.createObjectURL(blob);
                    const a = document.createElement('a');
                    a.href = url;
                    a.download = 'snapshot_' + Date.now() + '.jpg';
                    a.click();
                });
        }
    </script>
</body>
</html>
"""

@app.route('/')
def index():
    return render_template_string(HTML_TEMPLATE)

@app.route('/video_feed')
def video_feed():
    return Response(generate_frames(),
                    mimetype='multipart/x-mixed-replace; boundary=frame')

@app.route('/snapshot')
def snapshot():
    """Capture a single snapshot"""
    request = picam2.capture_request()
    request.save("main", "/tmp/snapshot.jpg")
    request.release()
    
    with open("/tmp/snapshot.jpg", "rb") as f:
        return Response(f.read(), mimetype='image/jpeg')

@app.route('/status')
def status():
    """Return camera status as JSON"""
    return {
        "status": "online",
        "resolution": "1280x720",
        "framerate": 25,
        "codec": "H264"
    }

if __name__ == '__main__':
    initialize_camera()
    app.run(host='0.0.0.0', port=5000, threaded=True)
```

### Alternative: RTSP Server with Picamera2

```python
#!/usr/bin/env python3
"""
RTSP Server using Picamera2
Requires: pip3 install av
"""

from picamera2 import Picamera2
from picamera2.encoders import H264Encoder
import subprocess
import sys

def start_rtsp_stream():
    picam2 = Picamera2()
    
    # Configure for 720p
    video_config = picam2.create_video_configuration(
        main={"size": (1280, 720), "format": "RGB888"}
    )
    picam2.configure(video_config)
    
    # Setup H.264 encoder
    encoder = H264Encoder(bitrate=2500000, repeat=True, iperiod=30)
    
    # Start streaming via pipe to mediamtx or VLC
    ffmpeg_cmd = [
        'ffmpeg',
        '-f', 'h264',
        '-i', '-',
        '-c:v', 'copy',
        '-f', 'rtsp',
        'rtsp://localhost:8554/camera'
    ]
    
    process = subprocess.Popen(ffmpeg_cmd, stdin=subprocess.PIPE)
    
    picam2.start_recording(encoder, process.stdin)
    
    try:
        while True:
            pass  # Keep running
    except KeyboardInterrupt:
        picam2.stop_recording()
        process.terminate()

if __name__ == '__main__':
    start_rtsp_stream()
```

### Create Systemd Service

```bash
sudo nano /etc/systemd/system/picamera-web.service
```

```ini
[Unit]
Description=Picamera2 Web Interface
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/ipcamera
ExecStart=/usr/bin/python3 /home/pi/ipcamera/camera_server.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable picamera-web.service
sudo systemctl start picamera-web.service
```

### Access Web Interface

```
http://<raspberry-pi-ip>:5000
```

---

## Comparison Summary

| Feature | MotionEyeOS | Motion | libcamera+RTSP | Picamera2+Flask |
|---------|-------------|---------|----------------|-----------------|
| **Ease of Setup** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| **CPU Usage** | Medium | High | Very Low | Low-Medium |
| **Hardware Accel** | Partial | No | Yes | Yes |
| **Web Interface** | Built-in | Basic | None | Custom |
| **Motion Detection** | Yes | Yes | No | Optional |
| **RTSP Support** | Yes | No | Yes | Optional |
| **Maintenance** | Deprecated | Active | Active | Active |
| **Customization** | Low | Medium | Medium | High |
| **Pi Zero W** | OK | Poor | Excellent | Good |
| **Pi Zero 2W** | Good | Fair | Excellent | Excellent |

---

## Recommended Configuration by Use Case

### 1. **Home Security Camera (Local Recording)**
**Choice:** Motion + Local Storage
- Motion detection triggers recording
- Save to USB drive or network share
- Email/webhook notifications

### 2. **Live Streaming to NVR (Blue Iris, Frigate, Home Assistant)**
**Choice:** libcamera-vid + RTSP (Option 3)
- Lowest latency
- Hardware accelerated
- Standard RTSP protocol
- Best performance

### 3. **Remote Monitoring with Web Access**
**Choice:** Picamera2 + Flask (Option 4)
- Custom web interface
- Mobile friendly
- Snapshot capability
- Extensible for AI/ML

### 4. **Quick Demo/Testing**
**Choice:** libcamera-vid + VLC
- Fastest setup
- No additional software
- Direct viewing in VLC

---

## Network Integration Examples

### Blue Iris NVR

```
Camera Type: Generic/ONVIF
Protocol: RTSP
URL: rtsp://camera-ip:8554/stream
Username/Password: (none required)
```

### Home Assistant (Frigate)

```yaml
cameras:
  pi_camera:
    ffmpeg:
      inputs:
        - path: rtsp://camera-ip:8554/stream
          roles:
            - detect
            - record
    detect:
      width: 1280
      height: 720
      fps: 25
```

### VLC Network Stream

```
Media > Open Network Stream
URL: rtsp://camera-ip:8554/stream
```

---

## Troubleshooting

### Camera Not Detected

```bash
# Check camera connection
libcamera-hello --list-cameras

# If no cameras found, check ribbon cable connection
# Verify config.txt has camera_auto_detect=1

# Reboot and test again
sudo reboot
```

### High CPU Usage

```bash
# Check CPU usage
htop

# For hardware acceleration, ensure using libcamera-vid
# Avoid software encoding (raspivid, motion without h264_v4l2m2m)
```

### Network Streaming Lag

```bash
# Reduce bitrate
--bitrate 1500000

# Reduce resolution
--width 640 --height 480

# Increase keyframe interval
--intra 60

# Use wired Ethernet instead of WiFi if possible
```

### Stream Drops/Stuttering

```bash
# Increase GPU memory
sudo nano /boot/firmware/config.txt
# Set: gpu_mem=256 (or 128 for Pi Zero W)

# Reduce frame rate
--framerate 15

# Enable buffer
--buffer-count 4
```

---

## Performance Benchmarks

### Pi Zero W (Single Core ARMv6)
- **720p @ 25fps:** ~10-15% CPU (with hardware encoding)
- **1080p @ 25fps:** ~25-30% CPU (with hardware encoding)
- **Recommended:** 720p @ 20-25fps for continuous recording

### Pi Zero 2W (Quad Core ARMv8)
- **720p @ 30fps:** ~8-12% CPU
- **1080p @ 30fps:** ~15-20% CPU
- **Recommended:** 1080p @ 30fps for best quality

---

## Security Considerations

1. **Change Default Credentials**
   ```bash
   # Change pi user password
   passwd
   ```

2. **Enable Firewall**
   ```bash
   sudo apt install ufw
   sudo ufw allow 22/tcp  # SSH
   sudo ufw allow 8554/tcp  # RTSP
   sudo ufw allow 5000/tcp  # Web interface
   sudo ufw enable
   ```

3. **Use VPN for Remote Access**
   - Consider WireGuard or Tailscale
   - Avoid exposing camera directly to internet

4. **Regular Updates**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

---

## Power Consumption Tips

- **Disable HDMI:** `sudo /usr/bin/tvservice -o` (saves ~25mA)
- **Disable Bluetooth:** Add `dtoverlay=disable-bt` to config.txt
- **Disable WiFi when using Ethernet:** `sudo iwconfig wlan0 txpower off`
- **Reduce GPU memory if not streaming:** `gpu_mem=128`

---

## Conclusion

For **Raspberry Pi Zero with OV5647 at 720p**, I recommend:

**Best Overall: Option 3 - libcamera-vid + v4l2rtspserver or mediamtx**
- Excellent performance with hardware acceleration
- Low CPU usage (~10-15%)
- Standard RTSP protocol
- Compatible with all major NVR systems
- Actively maintained

This setup provides the optimal balance of performance, compatibility, and ease of use for continuous 720p recording on Pi Zero hardware.