#include "dockadaptor.h"
#include "dodgemanager.h"

DockAdaptor::DockAdaptor(DodgeManager *parent)
    : QDBusAbstractAdaptor(parent)
    , m_manager(parent)
{
    setAutoRelaySignals(false);
}

void DockAdaptor::setOverlapping(bool value)
{
    m_manager->setOverlapping(value);
}

void DockAdaptor::setOverlapping(int value)
{
    m_manager->setOverlapping(value != 0);
}
