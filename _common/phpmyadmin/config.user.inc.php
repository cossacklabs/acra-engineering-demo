<?php
for ($i = 1; isset($hosts[$i - 1]); $i++) {
    // Use SSL for connection
    $cfg['Servers'][$i]['ssl'] = true;
    // Client secret key
    $cfg['Servers'][$i]['ssl_key'] = '/ssl/acra-client.key';
    // Client certificate
    $cfg['Servers'][$i]['ssl_cert'] = '/ssl/acra-client.crt';
    // Server certification authority
    $cfg['Servers'][$i]['ssl_ca'] = '/ssl/root.crt';
    // Disable SSL verification (see above note)
    $cfg['Servers'][$i]['ssl_verify'] = true;
}