# Chave de assinatura de release

A app é distribuída como APK fora da Play Store, por isso **somos nós que
guardamos a chave de assinatura**. O Android só instala uma atualização se o
APK novo estiver assinado com a **mesma chave** do que já está instalado.

> ⚠️ **Se a chave se perder**, nenhuma versão nova pode ser instalada por cima da
> atual: cada utilizador teria de desinstalar a app (perdendo os dados locais
> não sincronizados). Também muda o SHA-1 registado no login Google (Fase 4) e
> na verificação de programador da Google (Fase 6).
>
> ⚠️ **Se a chave for copiada por alguém**, essa pessoa pode publicar um APK
> falso que se instala por cima do verdadeiro. O repositório é **público**:
> nunca fazer commit da chave nem do `key.properties` (ambos estão no
> `android/.gitignore`).

## Onde está

| Ficheiro | Caminho | No Git? |
|---|---|---|
| Chave (PKCS12) | `%USERPROFILE%\.android-keys\habitapp\habitapp-release.jks` | Não |
| Palavras-passe e alias | `android/key.properties` (cópia em `%USERPROFILE%\.android-keys\habitapp\key.properties`) | Não |

O `android/app/build.gradle.kts` lê o `android/key.properties`. Sem ele (por
exemplo, num clone do repositório), o build de release é assinado com a chave
de debug (o aviso do Gradle não aparece na saída do `flutter build`): esse APK
**não serve para distribuir**. Antes de publicar um APK, verifica sempre o
certificado (ver abaixo).

Formato do `key.properties`:

```properties
storePassword=...
keyPassword=...
keyAlias=habitapp
storeFile=C:/Users/<utilizador>/.android-keys/habitapp/habitapp-release.jks
```

## Identificação do certificado

- DN: `CN=abelmandjr, O=abelmandjr`, RSA 4096, válido por 10 000 dias
  (até 2054), criado a 2026-10-07.
- **SHA-1:** `77:8D:84:20:08:6D:F3:AB:58:81:3B:F8:02:61:39:D4:E5:74:A7:CB`
- **SHA-256:** `60:01:00:01:31:51:E4:A6:8B:90:F3:04:55:BF:94:2A:9F:45:0F:B2:77:12:21:2C:53:6F:D3:BE:29:DB:76:AF`

Estes valores são públicos (estão em qualquer APK assinado) e são os que se
registam na Google Cloud (OAuth do login Google) e na Android Developer
Console.

## Cópia de segurança (fazer agora)

1. Copia a pasta `%USERPROFILE%\.android-keys\habitapp\` (os dois ficheiros)
   para **pelo menos dois sítios fora deste PC**, por exemplo:
   - um gestor de palavras-passe que aceite anexos (Bitwarden, 1Password…);
   - uma pen USB ou disco externo guardado em casa.
2. Se usares um serviço na nuvem, põe primeiro os ficheiros num arquivo
   cifrado (por exemplo, 7-Zip com AES-256 e uma palavra-passe forte que só
   tu sabes).
3. Guarda as palavras-passe também no gestor de palavras-passe (estão no
   `key.properties`).
4. Confirma que a cópia funciona: noutra pasta, corre
   `keytool -list -v -keystore habitapp-release.jks` com a palavra-passe e
   verifica que o SHA-1 é o de cima.

## Verificar um APK

```sh
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```

O `apksigner` está em `%LOCALAPPDATA%\Android\Sdk\build-tools\<versão>\`. O
SHA-1 tem de ser o de cima; se for
`75:2D:20:E3:…` é a chave de debug.
