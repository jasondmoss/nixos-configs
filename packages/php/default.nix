{ pkgs, ... }: {
    environment.systemPackages = (with pkgs; [
        #php83
        php84
    #]) ++ (with pkgs.php83Extensions; [
    #    bz2
    #    ctype
    #    curl
    #    fileinfo
    #    gd
    #    iconv
    #    imagick
    #    intl
    #    mbstring
    #    mysqlnd
    #    pdo
    #    pdo_dblib
    #    pdo_mysql
    #    pdo_odbc
    #    session
    #    simplexml
    #    tidy
    #    tokenizer
    #    xml
    #    xsl
    #    zip
    #    zlib
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
