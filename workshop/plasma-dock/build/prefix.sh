export PATH=/nix/store/pmw48fq7vv1i6jbydp30yb7lb41biszw-extra-cmake-modules-6.21.0/bin:$PATH

# LD_LIBRARY_PATH only needed if you are building without rpath
# export LD_LIBRARY_PATH=/nix/store/pmw48fq7vv1i6jbydp30yb7lb41biszw-extra-cmake-modules-6.21.0/lib:$LD_LIBRARY_PATH

export XDG_DATA_DIRS=/nix/store/pmw48fq7vv1i6jbydp30yb7lb41biszw-extra-cmake-modules-6.21.0/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}
export XDG_CONFIG_DIRS=/nix/store/pmw48fq7vv1i6jbydp30yb7lb41biszw-extra-cmake-modules-6.21.0/etc/xdg:${XDG_CONFIG_DIRS:-/etc/xdg}

export QT_PLUGIN_PATH=/nix/store/pmw48fq7vv1i6jbydp30yb7lb41biszw-extra-cmake-modules-6.21.0/lib/plugins:$QT_PLUGIN_PATH
export QML2_IMPORT_PATH=/nix/store/pmw48fq7vv1i6jbydp30yb7lb41biszw-extra-cmake-modules-6.21.0/lib/qml:$QML2_IMPORT_PATH

export QT_QUICK_CONTROLS_STYLE_PATH=/nix/store/pmw48fq7vv1i6jbydp30yb7lb41biszw-extra-cmake-modules-6.21.0/lib/qml/QtQuick/Controls.2/:$QT_QUICK_CONTROLS_STYLE_PATH

export MANPATH=/nix/store/pmw48fq7vv1i6jbydp30yb7lb41biszw-extra-cmake-modules-6.21.0/share/man:${MANPATH:-/usr/local/share/man:/usr/share/man}

export SASL_PATH=/nix/store/pmw48fq7vv1i6jbydp30yb7lb41biszw-extra-cmake-modules-6.21.0/lib/sasl2:${SASL_PATH:-/usr/lib/sasl2}
