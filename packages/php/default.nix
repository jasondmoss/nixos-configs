{ pkgs, ... }: {
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
        pdo_dblib
        pdo_mysql
        pdo_odbc
        session
        simplexml
        tidy
        tokenizer
        xml
        xsl
        zip
        zlib
    ]);
}
