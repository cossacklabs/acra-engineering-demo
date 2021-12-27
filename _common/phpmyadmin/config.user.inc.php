<?php
for ($i = 1; isset($hosts[$i - 1]); $i++) {
    // Use SSL for connection
    $cfg['Servers'][$i]['ssl'] = true;
    // Client secret key
    $cfg['Servers'][$i]['ssl_key'] = '/tmp.ssl/acra-client.key';
    // Client certificate
    $cfg['Servers'][$i]['ssl_cert'] = '/tmp.ssl/acra-client.crt';
    // Server certification authority
    $cfg['Servers'][$i]['ssl_ca'] = '/tmp.ssl/root.crt';
    // Disable SSL verification (see above note)
    $cfg['Servers'][$i]['ssl_verify'] = true;
    //console.log($cfg['Servers'][$i][);
file_put_contents('/tmp/test2.log', $cfg['Servers'][$i], FILE_APPEND | LOCK_EX);
}
