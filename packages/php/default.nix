{ config, lib, pkgs, ... }: {
    services.httpd = {
        enablePHP = true;

        # PHP 8.4
        phpPackage = pkgs.php84.buildEnv {
#            extensions = ({ enabled, all }: enabled ++ (with all; [
#                xdebug
#            ]));

            extraConfig = ''
memory_limit=2048M
xdebug.mode=debug
            '';
        };

        phpOptions = ''
allow_url_fopen = On
allow_url_include = On
display_errors = On
display_startup_errors = On
max_execution_time = 10000
max_input_time = 3000
mbstring.http_input = pass
mbstring.http_output = pass
mbstring.internal_encoding = pass
memory_limit = 2048M
post_max_size = 2048M
session.cookie_samesite = "Strict"
short_open_tag = Off
upload_max_filesize = 2048M
        '';
    };

    environment.systemPackages = (with pkgs; [
        php84
    ]) ++ (with pkgs.php84Extensions; [
        bz2
        ctype
        curl
        fileinfo
        gd
        iconv
        imagick
        intl
        mbstring
        mysqlnd
        openssl
        pdo
#        pdo_dblib
        pdo_mysql
        pdo_odbc
        session
        simplexml
        tidy
        tokenizer
        xdebug
        xml
        xsl
        zip
        zlib
    ]);
}
