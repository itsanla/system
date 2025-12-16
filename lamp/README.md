# Konfigurasi phpMyAdmin untuk Docker

## Langkah Konfigurasi

Edit file konfigurasi phpMyAdmin:
```bash
sudo nano /etc/phpmyadmin/config.inc.php
```

## Ubah Blok `if (!empty($dbname))`

Ganti seluruh isi dalam blok `if (!empty($dbname))` dengan konfigurasi berikut:

```php
/* Configure according to dbconfig-common if enabled */
if (!empty($dbname)) {
    $cfg['Servers'][$i]['auth_type'] = 'cookie';
    $cfg['Servers'][$i]['host'] = '127.0.0.1';
    $cfg['Servers'][$i]['connect_type'] = 'tcp';
    $cfg['Servers'][$i]['port'] = '3306';
    $i++;
}
```

## Restart Service

Setelah perubahan, restart Apache:
```bash
sudo systemctl restart apache2
```