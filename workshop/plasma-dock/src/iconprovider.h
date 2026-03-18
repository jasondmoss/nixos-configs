#pragma once
#include <QQuickImageProvider>
#include <QIcon>
#include <QPixmap>

class IconProvider : public QQuickImageProvider
{
public:
    IconProvider() : QQuickImageProvider(QQuickImageProvider::Pixmap) {}

    QPixmap requestPixmap(const QString &id, QSize *size, const QSize &requestedSize) override
    {
        const int sz = requestedSize.width() > 0 ? requestedSize.width() : 48;

        QIcon icon;
        if (id.startsWith(QLatin1Char('/')))
            icon = QIcon(id);
        else
            icon = QIcon::fromTheme(id);

        if (icon.isNull())
            icon = QIcon::fromTheme(QStringLiteral("application-x-executable"));

        const QPixmap px = icon.pixmap(sz, sz);
        if (size) *size = px.size();
        return px;
    }
};
