# mTLS demo

Mutual-TLS (mTLS) allows restricted login to a site, but not with a username and password. Only a device with a specially issued TLS certificate (and key) can access the site.

Paraphrasing [this blog post](https://blog.cloudflare.com/using-your-devices-as-the-key-to-your-apps/):

> My device must present a certificate demonstrating that it is authentic. To do that, I need to create a chain that can issue a certificate to my device.
> Cloudflare publishes an open source PKI toolkit, `cfssl`, which can solve that problem for me. `cfssl` lets me quickly create a Root CA and then use that root to generate a client certificate, which will ultimately can live on another device.

# Steps to set up

First pull the [Cloudflare SSL](https://github.com/cloudflare/cfssl) docker container.

```
docker pull cfssl/cfssl:latest
```

Next execute the `build.sh` script -- from within the `cfssl` container,

```
docker run -it --rm -v $(pwd)/cfssl:/run --user $(id -u) --entrypoint /run/build.sh -w /run cfssl/cfssl
```

Finally, run nginx to serve the top secret site,

```
docker run -it --rm -p 443:443 \
-v $(pwd)/nginx/site:/usr/share/nginx/html:ro \
-v $(pwd)/nginx/config/mtls.conf:/etc/nginx/nginx.conf:ro \
-v $(pwd)/cfssl/certs/localhost.pem:/etc/nginx/certs/localhost.pem:ro \
-v $(pwd)/cfssl/certs/localhost-key.pem:/etc/nginx/certs/localhost-key.pem:ro \
-v $(pwd)/cfssl/certs/combined.ca.pem:/etc/nginx/combined.ca.pem:ro \
nginx
```

And then test it!

```
curl -v \
    --cacert ./cfssl/certs/combined.ca.pem \
    --cert ./cfssl/certs/localhost.client.pem \
    --key ./cfssl/certs/localhost.client-key.pem \
    https://localhost
```

To make this work on a server other than localhost, I believe that you have to edit the `hosts` key in the server configuration in `build.sh`.

# Security

Before deploying be sure to secure keys and certificates. The only files that are needed for deployment are,

`nginx`:

  - certs/combined.ca.pem
  - certs/localhost.pem
  - certs/localhost-key.pem

client:

  - certs/combined.ca.pem
  - certs/localhost.client.pem
  - certs/localhost.client-key.pem

Everything else should be kept in a secure location.

# TODO

- Check out [nginx secure key storage](https://www.nginx.com/blog/secure-distribution-ssl-private-keys-nginx/#encrypt-keys) - encrypt the ssl certificate, require pw to decrypt before nginx will launch
