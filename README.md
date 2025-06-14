[![License](https://img.shields.io/github/license/mainsail-crew/virtual-klipper-printer.svg)](https://github.com/mainsail-crew/virtual-klipper-printer/blob/master/LICENSE 'License')
---
# Virtual-Klipper-Printer

### **Run a simulated Klipper 3D-Printer in a Docker container.**
---

### Quick Start:
1. Clone this repository
2. Open a terminal in the cloned folder
3. Run `docker compose up -d` to build the docker image and start the container in detached mode

The virtual printer will be available at:
- **Moonraker API**: `http://localhost:7125`
- **Mainsail Web Interface** (if enabled): `http://localhost:80`

---

## Mainsail Integration Options

This container supports three modes for Mainsail integration:

### 1. **No Mainsail (Default)**
- Minimal container with just Klipper + Moonraker
- Connect your own Mainsail instance to `http://localhost:7125`
- Smallest image size

### 2. **Mainsail Release Mode**
- Downloads and serves the latest stable Mainsail release
- Complete out-of-the-box experience
- Access at `http://localhost:80`

### 3. **Mainsail Development Mode**
- Builds Mainsail from source for development
- Optionally use local Mainsail repository
- Perfect for Mainsail developers

---

## Configuration

### Environment Variables

You can control Mainsail integration using these environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `INCLUDE_MAINSAIL` | `none` | Mainsail mode: `none`, `release`, or `dev` |
| `MAINSAIL_VERSION` | `latest` | Mainsail version for release mode |
| `MAINSAIL_DEV_PATH` | _(empty)_ | Path to local Mainsail repo for dev mode |
| `MAINSAIL_PORT` | `80` | Port to expose Mainsail on |

### Usage Examples

#### Basic Usage (No Mainsail)
```bash
docker compose up -d
```

#### With Mainsail Release
```bash
INCLUDE_MAINSAIL=release docker compose up -d --build
```

#### With Specific Mainsail Version
```bash
INCLUDE_MAINSAIL=release MAINSAIL_VERSION=2.9.0 docker compose up -d --build
```

#### Development Mode with Local Mainsail
```bash
# Option 1: Using environment variables
INCLUDE_MAINSAIL=dev MAINSAIL_DEV_PATH=/path/to/your/mainsail docker compose up -d --build

# Option 2: Using the development compose file (recommended)
MAINSAIL_DEV_PATH=/path/to/your/mainsail docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d --build
```

#### Custom Port for Mainsail
```bash
INCLUDE_MAINSAIL=release MAINSAIL_PORT=8080 docker compose up -d --build
```

### Environment File (.env)

You can also create a `.env` file in the project root:

```bash
# .env file
INCLUDE_MAINSAIL=release
MAINSAIL_VERSION=latest
MAINSAIL_PORT=80
```

### Development Compose File

For Mainsail development, you can use the provided `docker-compose.dev.yml`:

```bash
# Copy the example environment file
cp env.example .env

# Edit .env to set your Mainsail path
# MAINSAIL_DEV_PATH=./mainsail

# Start with development configuration
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d --build
```

---

### Configure a Dummy-Webcam:
To configure a dummy-webcam, use the following URLs:
   * Stream: `http://localhost:8110/?action=stream`
   * Snapshot: `http://localhost:8110/?action=snapshot`

When using Mainsail integration, the webcam is also available at:
   * Stream: `http://localhost/webcam/?action=stream`
   * Snapshot: `http://localhost/webcam/?action=snapshot`

---

### Common Docker commands:
* Get all container IDs: `docker ps -a`
* Get only the ID of running containers: `docker ps`
* Access a containers shell: `docker exec -it <CONTAINER ID> bash`
* Start/Restart/Stop a container: `docker container start/restart/stop <CONTAINER ID>`
* Rebuild image, recreate and start container : `docker compose up -d --build`

---

## Development Workflow

### For Mainsail Developers

1. **Clone your Mainsail fork**:
   ```bash
   git clone https://github.com/yourusername/mainsail.git
   ```

2. **Start the container with your local Mainsail**:
   ```bash
   # Method 1: Environment variable
   INCLUDE_MAINSAIL=dev MAINSAIL_DEV_PATH=./mainsail docker compose up -d --build
   
   # Method 2: Using dev compose file (recommended)
   MAINSAIL_DEV_PATH=./mainsail docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d --build
   ```

3. **Make changes to Mainsail**, rebuild, and the built files will be served

4. **Access your development Mainsail** at `http://localhost:80`

### For Quick Testing

1. **Use release mode** for testing with the latest stable Mainsail:
   ```bash
   INCLUDE_MAINSAIL=release docker compose up -d --build
   ```

2. **Access the complete setup** at `http://localhost:80`

---

## Troubleshooting

### Mainsail Not Loading
- Ensure you're using `--build` flag when changing `INCLUDE_MAINSAIL` modes
- Check container logs: `docker compose logs -f`
- Verify port 80 is not used by other services

### Development Mode Issues
- Ensure your local Mainsail directory path is correct
- For Mainsail repositories, point to the root directory (not the dist folder)  
- The container will automatically detect if it needs to use a `/dist` subdirectory

### Port Conflicts
- Change Mainsail port: `MAINSAIL_PORT=8080 docker compose up -d --build`
- Default ports: 7125 (Moonraker), 8110 (Webcam), 80 (Mainsail)

---

Current base image size: 742.72 MB  
*Note: Image size increases when including Mainsail (adds ~50-100MB depending on mode)*
