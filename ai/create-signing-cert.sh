#!/bin/bash
# Creates a self-signed code-signing identity named "Local Self-Signed" in the login keychain.
# A stable identity keeps the code signature constant across rebuilds, so macOS keeps the Accessibility and
# Screen Recording grants (ad-hoc signatures change on every build and orphan them).
# macOS asks for your login password to mark the certificate as trusted for code signing.
set -euo pipefail

name="${1:-Local Self-Signed}"
keychain="$HOME/Library/Keychains/login.keychain-db"

if security find-identity -v -p codesigning | grep -q "\"$name\""; then
  echo "Identity '$name' already exists"
  exit 0
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cd "$work"

cat > ext.cnf <<EOF
[req]
distinguished_name = dn
x509_extensions = ext
prompt = no
[dn]
CN = $name
[ext]
basicConstraints = critical,CA:false
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
EOF

openssl req -x509 -newkey rsa:2048 -nodes -keyout key.pem -out cert.pem -days 3650 -config ext.cnf
# -legacy: macOS `security import` can't read OpenSSL 3's default PKCS#12 encryption
openssl pkcs12 -export -legacy -inkey key.pem -in cert.pem -out id.p12 -passout pass:tmp
security import id.p12 -k "$keychain" -P tmp -T /usr/bin/codesign
security add-trusted-cert -r trustRoot -p codeSign -k "$keychain" cert.pem

security find-identity -v -p codesigning | grep "\"$name\""
echo "Created '$name'. Build with: SIGN_IDENTITY=\"$name\" ai/install.sh"
