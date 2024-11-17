{ pkgs, ... }: {
    environment.systemPackages = (with pkgs; [
        php84
    ]) ++ (with pkgs.php84Extensions; [

        bz2
        curl
        fileinfo
        gd
        imagick
        intl
        mbstring
        mysqlnd
        pdo
        pdo_dblib
        pdo_mysql
        pdo_odbc
        tidy
        xml
        xsl
        zip
        zlib

    ]);
}
