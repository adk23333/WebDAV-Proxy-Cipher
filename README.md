# WebDAV-Proxy-Cipher

This project is a transparent encryption/decryption proxy for standard WebDAV services. By acting as a middleman, it provides on-the-fly encryption and decryption based on the WebDAV protocol. It allows users to mount cloud storage via any WebDAV client and seamlessly play encrypted videos or view encrypted images. All operations within the WebDAV mount are fully transparent, with the system automatically handling the cryptographic processes.

As of now, the algorithms have been finalized, utilizing **RC4** and **AES-CTR** for enhanced security. The previous "mix" plaintext obfuscation scheme has been removed due to insufficient security and vulnerability to cracking. **AES-CTR** is the more secure and faster option. While **RC4**'s performance is slightly lower due to the Node.js implementation, it remains highly efficient—capable of saturating a 300Mbps bandwidth on hardware as modest as a TV box (primarily dependent on single-core performance).

With the algorithms established, the focus has shifted to code structure implementation. A stable release version might be expected soon. An experimental version is currently available for trial _via_ Docker.

_Special thanks to the original project_ [_alist-encrypt_](https://github.com/traceless/alist-encrypt "null") _for inspiration and reference._

## 1. Background

Many cloud drives and self-hosted NAS services provide WebDAV protocol support. A popular use case is mounting these drives as local to create a personal media center for on-demand video streaming.

However, both public cloud providers and private storage services face a common issue: sensitive or private resources may be scanned and deleted by the platform. Encrypting files before uploading is the simplest solution to avoid this "censorship," but it introduces a major limitation—traditional encrypted files cannot be streamed or previewed directly via WebDAV. Furthermore, sharing encrypted files becomes cumbersome.

**WebDAV-encrypt** was created to bridge this gap. It works with any standard WebDAV server, automatically encrypting files as they are uploaded through the proxy and decrypting them upon download. Because it uses stream encryption, it enables real-time streaming of encrypted videos and seamless browsing of images and documents. As long as your storage service supports WebDAV, it can be perfectly integrated.

**Target Use Case**: Users who prioritize file privacy and want to prevent cloud drive scanning, while maintaining the convenience of real-time streaming and high-speed downloads.

## 2. Encryption Principles

The implementation is straightforward. The conceptual predecessor can be found at [tlf-encryption](https://github.com/traceless/tlf-encryption "null"), which describes the mix obfuscation algorithm and the proxy implementation logic. While "mix" is suitable for basic obfuscation, it lacks sufficient strength for true encryption as it is susceptible to brute-force attacks based on file signatures.

### 2.1 HTTP Proxy Logic

Since WebDAV is built upon the HTTP protocol, implementing an HTTP proxy inherently provides WebDAV support. Since the encryption/decryption logic only targets the message **Body**, the **Headers** (Request/Response) remain untouched and are passed through transparently.

**Core Logic:**

1. **Request Interception**: Parse client request headers and pass them to the target WebDAV server. Encrypt the request Body based on business rules.
    
2. **Response Interception**: Receive response headers from the server and pass them back to the client. Decrypt the response Body in real-time based on business rules.
    

> While this logic can be implemented in many languages, Node.js is particularly well-suited for this due to its native `http` module and powerful stream-handling capabilities.

### 2.2 Technical Implementation

1. **httpProxy.js**: The core foundation of the HTTP proxy. It demonstrates how to intercept and process the HTTP Body stream for encryption/decryption. Node.js's `Stream` design—specifically the `Transform` stream interface—allows for elegant and highly efficient data processing.
    
2. **app.js**: The business logic layer built upon the base proxy. It specifically hijacks WebDAV traffic and uses Stream Ciphers to perform real-time encryption/decryption for uploads, downloads, and media streaming. Currently, it proxies the `/dav/*` path by default, but can be configured to proxy entire services (e.g., ~~Alist~~Openlist).
    
3. **Compatibility Verification**: The current Node.js version has been tested against mainstream services like Alibaba Cloud Drive. Core operations including upload, delete, move, and download (including full support for 302 redirects) are fully functional. Detailed configuration can be found in `config.js`.
    

The project currently supports two algorithms:

1. **AES-CTR**: A stream cipher mode implemented in the project. It is faster than both RC4 and ChaCha20. It is highly recommended for CPUs with armV8 architecture or higher, and X86 architectures that support the AES instruction set.
    
2. **RC4**: Provides sufficient security for most use cases (though minor theoretical flaws exist, they are negligible in this context). It is ideal for devices with CPUs that lack AES instructions and is extremely fast.
    

> **Recommendation**: **AES-CTR** is the preferred choice for most users due to its superior performance on modern hardware and higher security standards. RC4 remains a robust alternative for legacy device compatibility.

## 3. Installation and Usage

### Manual Execution

Ensure Node.js is installed on your system.

1. Download the project, enter the `node-proxy` directory, and run:
    
    - **Production (omit dev dependencies)**: 
	    `npm i --omit=dev`
    - **Development (all dependencies)**: 
	    `npm i`
2. Modify `conf/config.js` to add your target WebDAV server address and port, and configure the paths you wish to encrypt.
    
3. Start the service: 
	`npm run serve`
    

Once started, simply connect your WebDAV client to `http://127.0.0.1:5344/dav/` to access the transparent proxy.

### Docker Deployment (Local Build)

As pre-built images are no longer provided, please build locally using the provided `Dockerfile`.

**Example `compose.yaml`** (ensure it is in the same parent directory as the `src` folder):

```
services:
  webdav-encrypt:
    build:
      context: ./src                             # Path to the source code
    restart: unless-stopped
    hostname: webdav-encrypt
    container_name: webdav-encrypt
    volumes:
      - ./src/node-proxy/conf:/node-proxy/conf   # Mount configuration directory
    environment:
      TZ: Asia/Shanghai
      WEBDAV_HOST: 192.168.31.254:5254           # Upstream WebDAV address
    ports:
      - 5344:5344
    network_mode: bridge
```

**Startup Command:**

```
docker compose up -d --build
```

Mount `http://127.0.0.1:5344/dav/` in your client to begin use.

### Usage Notes

1. **Transparency**: All standard operations (rename, move, create folder) are passed through to the upstream server.
    
2. **Encryption Rules**: Files uploaded to designated "encrypted" directories via the proxy port will be encrypted. Accessing these files directly on the cloud drive will result in garbled/encrypted data. However, via the proxy, they appear and function as normal files.
    
3. **Paths**: Path settings support Regular Expressions. For example, `movie_encrypt/*` will ensure all files under the `movie_encrypt` directory are encrypted.
    

## 4. Current Status & Roadmaps

### Supported Features

- Real-time streaming and previewing of encrypted content (videos, images).
    
- Compatibility with major stream players like IINA, VLC, and Infuse.
    
- Fully transparent operations for the end-user.
    
- Password derivation based on folder names for easier sharing.
    
- Multi-directory support with unique passwords.
    

### Planned Features

- _Still in consideration._
    

### Limitations

- **Bandwidth**: As a traffic proxy, the deployment environment's network bandwidth directly impacts the user experience. Local or LAN deployment is recommended.
    
- **File Locking**: The WebDAV protocol itself lacks robust file locking. Concurrent writes from multiple clients may cause version conflicts; this is an inherent WebDAV limitation and not specific to this project.
    
- **Node.js Single-Process**: Performance may bottleneck in scenarios involving massive concurrent data encryption/decryption. While distributed deployment is possible, be wary of upstream WebDAV provider rate-limits or security flags (e.g., multi-IP back-to-origin).
    

## 5. FAQ

### 1. Proxy Server Performance

Testing on an S905L3A CPU shows that RC4 can saturate a **300Mbps** bandwidth, while AES-CTR can exceed **800Mbps+**. Hardware performance is unlikely to be the bottleneck for most home users.

### 2. Will there be implementations in other language?

Currently, there are **no** plans for implementation in other languages. Since this project is relatively simple, it can be easily implemented using either Go or Node.js. There are no necessitates of scale expansion till where Rust or Java is required. Furthermore, Go is not strictly necessary for the current performance requirements. Node.js was chosen due to its exceptional efficiency in Web development.

Additionally, Node.js supports `pkg` packaging, and the project already supports being bundled into cross-platform executables.

~~If you truly require ultra-high performance, please consider implementing it yourself using Rust + eBPF for maximum efficiency without leaving the kernel space. Nvidia Bluefield DPUs or FPGAs could also be excellent choices.~~

### 3. Future Roadmap

The current version is functional but not yet optimized for large-scale production use. We are focusing on improving compatibility with various WebDAV providers and refining additional features. We welcome feedback and suggestions from the community.