# Smartcard authentication

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/issues/726) in
[GitLab Premium](https://about.gitlab.com/pricing/) 11.6 as an experimental
feature. Smartcard authentication may change or be removed completely in future
releases.

Smartcards with X.509 certificates can be used to authenticate with GitLab.

## X.509 certificates

To use a smartcard with an X.509 certificate to authenticate with GitLab, `CN`
and `emailAddress` must be defined in the certificate. For example:

```
Certificate:
    Data:
        Version: 1 (0x0)
        Serial Number: 12856475246677808609 (0xb26b601ecdd555e1)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: O=Random Corp Ltd, CN=Random Corp
        Validity
            Not Before: Oct 30 12:00:00 2018 GMT
            Not After : Oct 30 12:00:00 2019 GMT
        Subject: CN=Gitlab User, emailAddress=gitlab-user@example.com
```

## Configure NGINX to request a client side certificate

In NGINX configuration, an **additional** server context must be defined with
the same configuration except:

- The additional NGINX server context must be configured to run on a different
  port:

  ```
  listen *:3444 ssl;
  ```

- The additional NGINX server context must be configured to require the client
  side certificate:

  ```
  ssl_verify_depth 2;
  ssl_client_certificate /etc/ssl/certs/CA.pem;
  ssl_verify_client on;
  ```

- The additional NGINX server context must be configured to forward the client
  side certificate:

  ```
  proxy_set_header    X-SSL-Client-Certificate    $ssl_client_escaped_cert;
  ```

For example, the following is an example server context in an NGINX
configuration file (eg. in `/etc/nginx/sites-available/gitlab-ssl`):

```
server {
    listen *:3444 ssl;

    # certificate for configuring SSL
    ssl_certificate /path/to/example.com.crt;
    ssl_certificate_key /path/to/example.com.key;

    ssl_verify_depth 2;
    # CA certificate for client side certificate verification
    ssl_client_certificate /etc/ssl/certs/CA.pem;
    ssl_verify_client on;

    location / {
        proxy_set_header    Host                        $http_host;
        proxy_set_header    X-Real-IP                   $remote_addr;
        proxy_set_header    X-Forwarded-For             $proxy_add_x_forwarded_for;
        proxy_set_header    X-Forwarded-Proto           $scheme;
        proxy_set_header    Upgrade                     $http_upgrade;
        proxy_set_header    Connection                  $connection_upgrade;

        proxy_set_header    X-SSL-Client-Certificate    $ssl_client_escaped_cert;

        proxy_read_timeout 300;

        proxy_pass http://gitlab-workhorse;
    }
}
```

## Configure GitLab for smartcard authentication

**For installations from source**

1. Edit `config/gitlab.yml`:

  ```yaml
  ## Smartcard authentication settings
  smartcard:
    # Allow smartcard authentication
    enabled: true

    # Path to a file containing a CA certificate
    ca_file: '/etc/ssl/certs/CA.pem'

    # Port where the client side certificate is requested by NGINX
    client_certificate_required_port: 3444
  ```

1. Save the file and restart GitLab for the changes to take effect.
