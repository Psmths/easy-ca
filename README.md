# easy-ca
 Bash script to quickly create a certificate authority using OpenSSL. This will generate a root certificate as well as one intermediate certificate. The process will create keys using the curve `secp521r1`, and encrypt the private keys with `AES256`. The selected message digest algorithm is `SHA512`.
