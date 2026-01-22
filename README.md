# OC Build Wizard

**OC Build Wizard** is a macOS application that automates the compilation of OpenCore directly from the official source code, also including the Btwise version (OpenCore_NO_ACPI), making it easier to generate the required files for Hackintosh usage.

The application was designed to simplify the build process while maintaining compatibility with both the official OpenCore releases and the **OpenCore_NO_ACPI**.

---

## Features

- Automatic compilation of **[Official OpenCore](https://github.com/acidanthera/OpenCorePkg)**
- Support for compiling [**OpenCore_NO_ACPI**](https://gitee.com/btwise/OpenCore_NO_ACPI.git)
- Automatic organization of generated files
- Installation of files into protected system locations
- User-friendly interface to simplify the build process
- Use of official OpenCore project tools

---

## Root Privileges

OC Build Wizard uses the **AuthorizationExecuteWithPrivileges** API to execute commands that require administrator privileges, such as:

- Copying files to protected directories  
  *(Only: IASL, MTOC, NDISASM, and NASM)*  
  Destination: `/usr/local/bin`

> [!WARNING] 
> **Important Notice**  
>The **AuthorizationExecuteWithPrivileges** API is deprecated in recent versions of macOS. It may still work, but its use is not recommended for new projects and it may stop functioning in future macOS releases.

---

## Requirements

- macOS
- Xcode (Command Line Tools installed)
- Internet access to download repositories
- Administrator privileges

---

> [!IMPORTANT]
> ## Legal Notice
> - This project is not officially affiliated with the OpenCore team.
> - Use at your own risk.
> - Make sure to comply with the licenses of the projects used.

---

## License

- This project is distributed under the [**BSD-3-Clause**](https://github.com/Mirone/OC-Build-Wizard?tab=BSD-3-Clause-1-ov-file#) license.

---

## Credits

- **OpenCore Team** – [Acidanthera](https://github.com/acidanthera)
- **OpenCore_NO_ACPI** - [Btwise](https://gitee.com/btwise/OpenCore_NO_ACPI.git)
