/****************************************************************************
** Meta object code from reading C++ file 'appmodel.h'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.10.1)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../src/appmodel.h"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'appmodel.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 69
#error "This file was generated using the moc from 6.10.1. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

#ifndef Q_CONSTINIT
#define Q_CONSTINIT
#endif

QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
QT_WARNING_DISABLE_GCC("-Wuseless-cast")
namespace {
struct qt_meta_tag_ZN8AppModelE_t {};
} // unnamed namespace

template <> constexpr inline auto AppModel::qt_create_metaobjectdata<qt_meta_tag_ZN8AppModelE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "AppModel",
        "countChanged",
        "",
        "dockEdgeChanged",
        "dodgeEnabledChanged",
        "onRunningChanged",
        "desktopId",
        "running",
        "onUnknownAppStarted",
        "onUnknownAppStopped",
        "setDockEdge",
        "edge",
        "setDodgeEnabled",
        "v",
        "launch",
        "index",
        "activateOrLaunch",
        "moveApp",
        "from",
        "to",
        "pinApp",
        "unpinApp",
        "count",
        "dockEdge",
        "dodgeEnabled",
        "Roles",
        "DesktopIdRole",
        "NameRole",
        "IconNameRole",
        "ExecRole",
        "RunningRole",
        "IsSeparatorRole",
        "IsPinnedRole"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'countChanged'
        QtMocHelpers::SignalData<void()>(1, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'dockEdgeChanged'
        QtMocHelpers::SignalData<void()>(3, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'dodgeEnabledChanged'
        QtMocHelpers::SignalData<void()>(4, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'onRunningChanged'
        QtMocHelpers::SlotData<void(const QString &, bool)>(5, 2, QMC::AccessPrivate, QMetaType::Void, {{
            { QMetaType::QString, 6 }, { QMetaType::Bool, 7 },
        }}),
        // Slot 'onUnknownAppStarted'
        QtMocHelpers::SlotData<void(const QString &)>(8, 2, QMC::AccessPrivate, QMetaType::Void, {{
            { QMetaType::QString, 6 },
        }}),
        // Slot 'onUnknownAppStopped'
        QtMocHelpers::SlotData<void(const QString &)>(9, 2, QMC::AccessPrivate, QMetaType::Void, {{
            { QMetaType::QString, 6 },
        }}),
        // Method 'setDockEdge'
        QtMocHelpers::MethodData<void(int)>(10, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 11 },
        }}),
        // Method 'setDodgeEnabled'
        QtMocHelpers::MethodData<void(bool)>(12, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 13 },
        }}),
        // Method 'launch'
        QtMocHelpers::MethodData<void(int) const>(14, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 15 },
        }}),
        // Method 'activateOrLaunch'
        QtMocHelpers::MethodData<void(int)>(16, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 15 },
        }}),
        // Method 'moveApp'
        QtMocHelpers::MethodData<void(int, int)>(17, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 18 }, { QMetaType::Int, 19 },
        }}),
        // Method 'pinApp'
        QtMocHelpers::MethodData<void(const QString &)>(20, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 6 },
        }}),
        // Method 'unpinApp'
        QtMocHelpers::MethodData<void(int)>(21, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 15 },
        }}),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'count'
        QtMocHelpers::PropertyData<int>(22, QMetaType::Int, QMC::DefaultPropertyFlags, 0),
        // property 'dockEdge'
        QtMocHelpers::PropertyData<int>(23, QMetaType::Int, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 1),
        // property 'dodgeEnabled'
        QtMocHelpers::PropertyData<bool>(24, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 2),
    };
    QtMocHelpers::UintData qt_enums {
        // enum 'Roles'
        QtMocHelpers::EnumData<enum Roles>(25, 25, QMC::EnumFlags{}).add({
            {   26, Roles::DesktopIdRole },
            {   27, Roles::NameRole },
            {   28, Roles::IconNameRole },
            {   29, Roles::ExecRole },
            {   30, Roles::RunningRole },
            {   31, Roles::IsSeparatorRole },
            {   32, Roles::IsPinnedRole },
        }),
    };
    return QtMocHelpers::metaObjectData<AppModel, qt_meta_tag_ZN8AppModelE_t>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums);
}
Q_CONSTINIT const QMetaObject AppModel::staticMetaObject = { {
    QMetaObject::SuperData::link<QAbstractListModel::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN8AppModelE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN8AppModelE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN8AppModelE_t>.metaTypes,
    nullptr
} };

void AppModel::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<AppModel *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->countChanged(); break;
        case 1: _t->dockEdgeChanged(); break;
        case 2: _t->dodgeEnabledChanged(); break;
        case 3: _t->onRunningChanged((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<bool>>(_a[2]))); break;
        case 4: _t->onUnknownAppStarted((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 5: _t->onUnknownAppStopped((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 6: _t->setDockEdge((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 7: _t->setDodgeEnabled((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 8: _t->launch((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 9: _t->activateOrLaunch((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 10: _t->moveApp((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2]))); break;
        case 11: _t->pinApp((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 12: _t->unpinApp((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (AppModel::*)()>(_a, &AppModel::countChanged, 0))
            return;
        if (QtMocHelpers::indexOfMethod<void (AppModel::*)()>(_a, &AppModel::dockEdgeChanged, 1))
            return;
        if (QtMocHelpers::indexOfMethod<void (AppModel::*)()>(_a, &AppModel::dodgeEnabledChanged, 2))
            return;
    }
    if (_c == QMetaObject::ReadProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast<int*>(_v) = _t->rowCount(); break;
        case 1: *reinterpret_cast<int*>(_v) = _t->dockEdge(); break;
        case 2: *reinterpret_cast<bool*>(_v) = _t->dodgeEnabled(); break;
        default: break;
        }
    }
    if (_c == QMetaObject::WriteProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 1: _t->setDockEdge(*reinterpret_cast<int*>(_v)); break;
        case 2: _t->setDodgeEnabled(*reinterpret_cast<bool*>(_v)); break;
        default: break;
        }
    }
}

const QMetaObject *AppModel::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *AppModel::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN8AppModelE_t>.strings))
        return static_cast<void*>(this);
    return QAbstractListModel::qt_metacast(_clname);
}

int AppModel::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QAbstractListModel::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 13)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 13;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 13)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 13;
    }
    if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 3;
    }
    return _id;
}

// SIGNAL 0
void AppModel::countChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}

// SIGNAL 1
void AppModel::dockEdgeChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, nullptr);
}

// SIGNAL 2
void AppModel::dodgeEnabledChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 2, nullptr);
}
QT_WARNING_POP
