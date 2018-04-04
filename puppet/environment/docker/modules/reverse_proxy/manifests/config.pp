###
### config.pp, configure nginx.
###
class reverse_proxy::config {
    ## local variables
    $type              = $::reverse_proxy::type
    $self_signed       = $::reverse_proxy::self_signed
    $vhost             = $::reverse_proxy::vhost
    $host_port         = $::reverse_proxy::host_port
    $webserver_port    = $::reverse_proxy::webserver_port
    $proxy             = $::reverse_proxy::proxy
    $cert_path         = $::reverse_proxy::cert_path
    $pkey_path         = $::reverse_proxy::pkey_path
    $cert_country      = $::reverse_proxy::cert_country
    $cert_org          = $::reverse_proxy::cert_org
    $cert_state        = $::reverse_proxy::cert_state
    $cert_locality     = $::reverse_proxy::cert_locality
    $cert_unit         = $::reverse_proxy::cert_unit
    $cert_bit          = $::reverse_proxy::cert_bit
    $cert_days         = $::reverse_proxy::cert_days

    ## nginx reverse proxy
    ##
    ## @497, redirect 'http://' to 'https://'
    ##
    reverse_proxy::resource::vhost { $reverse_proxy::vhost:
        ssl             => true,
        ssl_cert        => "${cert_path}/${vhost}_${type}.crt",
        ssl_key         => "${pkey_path}/${vhost}_${type}.key",
        listen_port     => $reverse_proxy::listen_port,
        ssl_port        => $reverse_proxy::listen_port,
        error_pages     => {
            '497' => "https://\$host:${host_port}\$request_uri",
        },
        proxy           => "${proxy}:${webserver_port}",
    }

    ## create ssl certificate
    if $self_signed {
        file { "/root/build/ssl-nginx-${type}":
            ensure         => present,
            content        => dos2unix(template("webserver/ssl-${type}.erb")),
            owner          => 'root',
            group          => 'root',
            mode           => '0700',
            require        => File['/root/build'],
            notify         => Exec["create-certificate-${type}"],
        }

        exec { "create-certificate-${type}":
            command        => "./ssl-nginx-${type}",
            cwd            => '/root/build',
            path           => '/usr/bin',
            provider       => shell,
            refreshonly    => true,
        }
    }

    else {
        notify {'Please remember to provide your own certificate!':}
    }
}