{ config, lib, pkgs, ... }: {

    networking = {
        hostName = "atreides";
        enableIPv6 = true;

        extraHosts = ''
            127.0.0.1 adminer.test
            127.0.0.1 jdmlabs-craft.test
            127.0.0.1 jdmlabs-drupal.test
            127.0.0.1 jdmlabs-laravel.test
            127.0.0.1 canoe-north.test
            127.0.0.1 hay-river.test
            # 127.0.0.1 travel-media.test
            # 127.0.0.1 travel-trade.test
            # 127.0.0.1 spectacularnwt.test
            127.0.0.1 localhost
            127.0.0.1 localhost.localdomain
        '';

        firewall = {
            allowPing = true;
            allowedTCPPorts = [ 22 80 443 1025 1143 33728 ];
        };

        networkmanager = {
            enable = true;
            insertNameservers = [ "127.0.0.1" ];
        };
    };


    services = {
        coredns = {
            enable = true;
            config = ''
                . {
                    # Cloudflare and Google
                    forward . 1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4
                    cache
                }

                local {
                    template IN A {
                        answer "{{ .Name }} 0 IN A 127.0.0.1"
                    }
                }
            '';
        };

        httpd = {
            enable = true;
            adminAddr = "me@localhost";
            user = "me";
            group = "users";
            extraModules = [ "http2" ];
            enablePHP = true;

            phpPackage = pkgs.php82.buildEnv {
                extensions = ({ enabled, all }: enabled);
                extraConfig = "memory_limit = 1024M";
            };

            phpOptions = ''
                display_errors = On
                display_startup_errors = On
                post_max_size = 200M
                upload_max_filesize = 1024M
                max_execution_time = 6000
                max_input_time = 3000
                mbstring.http_input = pass
                mbstring.http_output = pass
                mbstring.internal_encoding = pass
                memory_limit = 1024M;
                allow_url_include = On;
            '';

            virtualHosts = {
                "adminer" = {
                    documentRoot = "/srv/adminer";
                    servedDirs = [{
                        urlPath = "/srv/adminer";
                        dir = "/srv/adminer";
                    }];
                    serverAliases = [ "jdmlabs-adminer.test" ];
                    extraConfig = ''
                        <Directory "/srv/adminer">
                            Options +Indexes +ExecCGI +FollowSymlinks -SymLinksIfOwnerMatch
                            RewriteEngine On
                            DirectoryIndex index.php
                            Require all granted
                            AllowOverride All
                        </Directory>
                    '';
                };

                "jdmlabs-craft" = {
                    documentRoot = "/srv/jdmlabs-craft/web";
                    servedDirs = [{
                        urlPath = "/srv/jdmlabs-craft/web";
                        dir = "/srv/jdmlabs-craft/web";
                    }];
                    serverAliases = [ "jdmlabs-craft.test" ];
                    extraConfig = ''
                        <Directory "/srv/jdmlabs-craft/web">
                            Options +Indexes +ExecCGI +FollowSymlinks -SymLinksIfOwnerMatch
                            RewriteEngine On
                            DirectoryIndex index.html index.html.var index.php
                            Require all granted
                            AllowOverride All
                        </Directory>
                    '';
                };

                "jdmlabs-drupal" = {
                    documentRoot = "/srv/jdmlabs-drupal/web";
                    servedDirs = [{
                        urlPath = "/srv/jdmlabs-drupal/web";
                        dir = "/srv/jdmlabs-drupal/web";
                    }];
                    serverAliases = [ "jdmlabs-drupal.test" "jdmlabs-drupal-redirect.test" ];
                    extraConfig = ''
                        <Directory "/srv/jdmlabs-drupal/web">
                            Options +Indexes +ExecCGI +FollowSymlinks -SymLinksIfOwnerMatch
                            RewriteEngine On
                            DirectoryIndex index.html index.html.var index.php
                            Require all granted
                            AllowOverride All
                        </Directory>
                    '';
                };

                "jdmlabs-laravel" = {
                    documentRoot = "/srv/jdmlabs-laravel/public";
                    servedDirs = [{
                        urlPath = "/srv/jdmlabs-laravel/public";
                        dir = "/srv/jdmlabs-laravel/public";
                    }];
                    serverAliases = [ "jdmlabs-laravel.test" "jdmlabs-laravel-redirect.test" ];
                    extraConfig = ''
                        <Directory "/srv/jdmlabs-laravel/public">
                            Options +Indexes +ExecCGI +FollowSymlinks -SymLinksIfOwnerMatch
                            RewriteEngine On
                            DirectoryIndex index.html index.html.var index.php
                            Require all granted
                            AllowOverride All
                        </Directory>
                    '';
                };

                "canoe-north" = {
                    documentRoot = "/srv/canoe-north/web";
                    servedDirs = [{
                        urlPath = "/srv/canoe-north/web";
                        dir = "/srv/canoe-north/web";
                    }];
                    serverAliases = [ "canoe-north.test" "canoe-north-redirect.test" ];
                    extraConfig = ''
                        <Directory "/srv/canoe-north/web">
                            Options +Indexes +ExecCGI +FollowSymlinks -SymLinksIfOwnerMatch
                            RewriteEngine On
                            DirectoryIndex index.html index.html.var index.php
                            Require all granted
                            AllowOverride All
                        </Directory>
                    '';
                };

                "hay-river" = {
                    documentRoot = "/srv/hay-river/web";
                    servedDirs = [{
                        urlPath = "/srv/hay-river/web";
                        dir = "/srv/hay-river/web";
                    }];
                    serverAliases = [ "hay-river.test" "hay-river-redirect.test" ];
                    extraConfig = ''
                        <Directory "/srv/hay-river/web">
                            Options +Indexes +ExecCGI +FollowSymlinks -SymLinksIfOwnerMatch
                            RewriteEngine On
                            DirectoryIndex index.html index.html.var index.php
                            Require all granted
                            AllowOverride All
                        </Directory>
                    '';
                };

                # "spectacularnwt" = {
                #     documentRoot = "/srv/spectacularnwt/web";
                #     servedDirs = [{
                #         urlPath = "/srv/spectacularnwt/web";
                #         dir = "/srv/spectacularnwt/web";
                #     }];
                #     serverAliases = [ "spectacularnwt.test" "spectacularnwt-redirect.test" ];
                #     extraConfig = ''
                #         <Directory "/srv/spectacularnwt/web">
                #             Options +Indexes +ExecCGI +FollowSymlinks -SymLinksIfOwnerMatch
                #             RewriteEngine On
                #             DirectoryIndex index.html index.html.var index.php
                #             Require all granted
                #             AllowOverride All
                #         </Directory>
                #     '';
                # };

                # "travel-media" = {
                #     documentRoot = "/srv/travel-media/web";
                #     servedDirs = [{
                #         urlPath = "/srv/travel-media/web";
                #         dir = "/srv/travel-media/web";
                #     }];
                #     serverAliases = [ "travel-media.test" "travel-media-redirect.test" ];
                #     extraConfig = ''
                #         <Directory "/srv/travel-media/web">
                #             Options +Indexes +ExecCGI +FollowSymlinks -SymLinksIfOwnerMatch
                #             RewriteEngine On
                #             DirectoryIndex index.html index.html.var index.php
                #             Require all granted
                #             AllowOverride All
                #         </Directory>
                #     '';
                # };

                # "travel-trade" = {
                #     documentRoot = "/srv/travel-trade/web";
                #     servedDirs = [{
                #         urlPath = "/srv/travel-trade/web";
                #         dir = "/srv/travel-trade/web";
                #     }];
                #     serverAliases = [ "travel-trade.test" "travel-trade-redirect.test" ];
                #     extraConfig = ''
                #         <Directory "/srv/travel-trade/web">
                #             Options +Indexes +ExecCGI +FollowSymlinks -SymLinksIfOwnerMatch
                #             RewriteEngine On
                #             DirectoryIndex index.html index.html.var index.php
                #             Require all granted
                #             AllowOverride All
                #         </Directory>
                #     '';
                # };
            };
        };

        mysql = {
            enable = true;
            package = pkgs.mariadb;

            settings = {
                mysqld = {
                    transaction-isolation = "READ-COMMITTED";
                };
            };

            ensureUsers = [
                {
                    name = "me";
                    ensurePermissions = {
                        "*.*" = "ALL PRIVILEGES";
                    };
                }
            ];
        };
    };

}
