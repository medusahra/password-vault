# PASSWORD-VAULT

> Encrypted password manager · Zero cloud dependencies · Military-grade AES-256

```
┌─────────────────────────────────────────────────┐
│  [ENCRYPTED VAULT INITIALIZED]                  │
│  AES-256-CBC · PBKDF2 · 100K iterations         │
│  Local storage only · No telemetry · No cloud   │
└─────────────────────────────────────────────────┘
```

---

## FILOSOFÍA

En un ecosistema donde las contraseñas se almacenan en servidores ajenos, donde los "password managers" dependen de clouds corporativos y servicios de terceros, este vault opera bajo un principio diferente: **soberanía total de datos**. 

Tus contraseñas nunca salen de tu máquina. No hay sincronización automática porque no hay servidor. No hay subscripciones mensuales porque no hay infraestructura externa. Solo AES-256, un master password que solo tú conoces, y un archivo encriptado en tu disco local.

Construido con el entendimiento de que la conveniencia tiene un precio: el control.

---

## ARQUITECTURA DE SEGURIDAD

### Encriptación
```ruby
Algorithm: AES-256-CBC
Key Derivation: PBKDF2-HMAC-SHA256
Iterations: 100,000
Salt: Random 16 bytes per encryption
IV: Random per encryption operation
```

### Flujo de operación

```
┌─────────────────┐
│ Master Password │
└────────┬────────┘
         │
         ▼
  ┌──────────────┐
  │ PBKDF2-HMAC  │──► 100,000 iterations
  │   SHA-256    │    + random salt
  └──────┬───────┘
         │
         ▼
  ┌──────────────┐
  │  AES-256-CBC │──► Encrypt/Decrypt
  │ + Random IV  │    vault data
  └──────┬───────┘
         │
         ▼
  ┌──────────────┐
  │  ~/.password │
  │  _vault.enc  │
  └──────────────┘
```

### ¿Por qué es seguro?

1. **AES-256:** Estándar militar. Inviable de romper por fuerza bruta (2^256 combinaciones)
2. **PBKDF2:** Deriva el master password en clave de encriptación. 100K iteraciones hacen costoso el ataque por diccionario
3. **Salt único:** Cada encriptación usa sal diferente. Imposibilita rainbow tables
4. **IV aleatorio:** Initialization Vector único por operación. Mismo plaintext genera ciphertexts distintos
5. **Local-only:** Sin red, sin telemetría, sin surface de ataque remoto

---

## FEATURES

### Core
- ✅ **AES-256-CBC encryption** (military-grade)
- ✅ **Master password protection** (PBKDF2 · 100K iterations)
- ✅ **Zero cloud dependencies** (local storage only)
- ✅ **Offline-first** (no network requests)

### Funcionalidad
- ✅ **Add password:** Store credentials encrypted
- ✅ **Get password:** Retrieve and decrypt on demand
- ✅ **List entries:** View all stored accounts
- ✅ **Generate strong passwords:** Cryptographically secure random
- ✅ **Delete password:** Remove entries permanently
- ✅ **Export vault:** Backup encrypted file
- ✅ **Copy to clipboard:** Quick access (macOS)

---

## INSTALACIÓN

### Requisitos
- Ruby 2.7+ (viene preinstalado en macOS)
- Gem: `colorize` (para UI coloreada)

### Linux (Debian/Ubuntu)
```bash
sudo apt update
sudo apt install ruby-full
gem install colorize
```

### macOS
```bash
brew install ruby
gem install colorize
```

### Clonar y ejecutar
```bash
git clone https://github.com/medusahra/password-vault.git
cd password-vault
ruby vault.rb
```

---

## USO

### Primera ejecución
```bash
ruby vault.rb
```

El sistema solicitará crear un **master password**. Este es el único password que necesitas recordar. No hay recuperación posible si lo olvidas.

### Operaciones disponibles

```
[1] Add password       → Almacenar nueva credencial
[2] Get password       → Recuperar password existente
[3] List all entries   → Ver todos los servicios guardados
[4] Generate password  → Crear password fuerte (random)
[5] Delete password    → Eliminar entrada permanentemente
[6] Export vault       → Backup del archivo encriptado
[0] Exit               → Cerrar vault de forma segura
```

### Workflow típico

```bash
# 1. Agregar password de GitHub
[1] → "github" → "mypassword123"

# 2. Generar password fuerte para nuevo servicio
[4] → Password aleatorio generado
[1] → "twitter" → [pegar password generado]

# 3. Recuperar password
[2] → "github" → Password copiado al clipboard

# 4. Backup
[6] → Vault exportado a archivo timestamped
```

---

## ESTRUCTURA DE DATOS

### Vault file: `~/.password_vault.enc`

```
┌─────────────────────────────────────────┐
│ ENCRYPTED BLOB (AES-256-CBC)            │
├─────────────────────────────────────────┤
│ Salt (16 bytes random)                  │
│ IV (16 bytes random)                    │
│ Ciphertext (variable length)            │
│   ↳ JSON serialized passwords           │
│   ↳ {"service": "password", ...}        │
└─────────────────────────────────────────┘
```

Decrypted structure:
```ruby
{
  "github" => "mypassword123",
  "twitter" => "Xk9#mP2$vL8@",
  "email" => "secure_pass_2024"
}
```

---

## GENERACIÓN DE PASSWORDS

El generador usa `SecureRandom` de Ruby (cryptographically secure):

```ruby
charset = [
  ('a'..'z'),      # lowercase
  ('A'..'Z'),      # uppercase  
  ('0'..'9'),      # digits
  ['!', '@', '#']  # symbols
].flat_map(&:to_a)

password = Array.new(16) { charset.sample }.join
# Output: "Xk9#mP2$vL8@nQ4R"
```

- **Longitud:** 16 caracteres
- **Entropía:** ~95 bits (2^95 combinaciones)
- **Resistencia:** Inviable romper por fuerza bruta

---

## CONSIDERACIONES DE SEGURIDAD

### ⚠️ CRÍTICO

1. **NO PIERDAS TU MASTER PASSWORD**
   - No hay sistema de recuperación
   - No hay "forgot password"
   - Si lo olvidas, pierdes acceso permanentemente

2. **BACKUP REGULAR**
   ```bash
   # Backup manual
   cp ~/.password_vault.enc ~/backups/vault_$(date +%Y%m%d).enc
   
   # O usar la función [6] Export vault
   ```

3. **MASTER PASSWORD FUERTE**
   - Mínimo 12 caracteres
   - Mezcla de mayúsculas, minúsculas, números, símbolos
   - No usar palabras de diccionario
   - Ejemplo: `Tr4nsc3nd&Mach1n3!`

### Threat Model

**Protege contra:**
- ✅ Robo de disco/laptop (vault encriptado)
- ✅ Malware que lee archivos (sin master password no hay acceso)
- ✅ Ataques de fuerza bruta (100K iterations PBKDF2)

**NO protege contra:**
- ❌ Keylogger activo mientras escribes master password
- ❌ Backdoor en Ruby interpreter
- ❌ Physical access mientras vault está desbloqueado

### Best Practices

```bash
# 1. Usar en ambiente seguro
# No ejecutar en máquinas públicas/compartidas

# 2. Limpiar clipboard después de copiar
# El password permanece en clipboard hasta próximo copy

# 3. Cerrar vault cuando no se usa
# Opción [0] Exit limpia memoria

# 4. Permisos restrictivos del vault file
chmod 600 ~/.password_vault.enc
```

---

## ARQUITECTURA DEL CÓDIGO

### `vault.rb` - Componentes principales

```ruby
class PasswordVault
  ├── initialize(master_password)
  │   └── Deriva clave AES desde master password
  │
  ├── encrypt(data)
  │   └── AES-256-CBC + salt + IV random
  │
  ├── decrypt(encrypted_data)
  │   └── Extrae salt/IV, decripta con clave derivada
  │
  ├── add_password(service, password)
  ├── get_password(service)
  ├── list_services
  ├── generate_password
  └── delete_password(service)
```

### Dependencies

```ruby
require 'openssl'      # AES encryption
require 'json'         # Data serialization
require 'securerandom' # Crypto-safe random
require 'colorize'     # Terminal colors (optional)
```

---

## ROADMAP

### v2.0 (Planned)

- [ ] **Multi-vault support:** Múltiples vaults con diferentes master passwords
- [ ] **Password strength checker:** Análisis de entropía al agregar
- [ ] **Auto-lock timer:** Cerrar vault tras X minutos de inactividad
- [ ] **Encrypted notes:** Almacenar notas seguras además de passwords
- [ ] **Import from CSV:** Migración desde otros password managers
- [ ] **2FA TOTP generator:** Códigos 2FA integrados

### v3.0 (Future)

- [ ] **Cross-platform clipboard:** Soporte universal (Linux/macOS/Windows)
- [ ] **Password history:** Track de passwords anteriores
- [ ] **Breach detection:** Check contra bases de datos de leaks (Have I Been Pwned API)

---

## COMPARACIÓN CON ALTERNATIVAS

| Feature | password-vault | LastPass | 1Password | Bitwarden |
|---------|---------------|----------|-----------|-----------|
| **Encriptación** | AES-256 | AES-256 | AES-256 | AES-256 |
| **Local-only** | ✅ | ❌ | ❌ | ❌ |
| **Zero cloud** | ✅ | ❌ | ❌ | ❌ |
| **Open source** | ✅ | ❌ | ❌ | ✅ |
| **Costo** | $0 | $36/año | $36/año | $10/año |
| **Dependencies** | 1 gem | Internet | Internet | Internet |
| **Telemetry** | Zero | Sí | Sí | Opcional |

---

## CRÉDITOS

**Desarrollado por:** [medusahra](https://github.com/medusahra)

**Stack:** Ruby · OpenSSL · AES-256-CBC · PBKDF2

**Links:**
- X: [@medusahra](https://x.com/medusahra)
- GitHub: [github.com/medusahra](https://github.com/medusahra)
- Portfolio: [medusahra.github.io](https://medusahra.github.io)

---

## LICENCIA

MIT License

```
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.
```

---

## DISCLAIMER

Este software es para uso educacional y personal. El autor no se hace responsable por pérdida de datos, passwords olvidados, o cualquier daño derivado del uso de este software. 

**RECUERDA:** Si pierdes tu master password, pierdes acceso permanente a tu vault. No hay backdoor. No hay recuperación. Esa es precisamente la razón por la que es seguro.

---

*// PASSWORD-VAULT v1.0 · LOCAL-FIRST ENCRYPTED STORAGE · ZERO CLOUD DEPENDENCIES //*
