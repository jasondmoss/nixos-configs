/****************************************************************************
** Meta object code from reading C++ file 'layershellwindow.h'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.10.1)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../src/layershellwindow.h"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'layershellwindow.h' doesn't include <QObject>."
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
struct qt_meta_tag_ZN16LayerShellWindowE_t {};
} // unnamed namespace

template <> constexpr inline auto LayerShellWindow::qt_create_metaobjectdata<qt_meta_tag_ZN16LayerShellWindowE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "LayerShellWindow",
        "edgeChanged",
        "",
        "dockSizeChanged",
        "exclusiveZoneChanged",
        "layerShellReady",
        "edge",
        "Edge",
        "dockSize",
        "exclusiveZone",
        "Top",
        "Bottom",
        "Left",
        "Right"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'edgeChanged'
        QtMocHelpers::SignalData<void()>(1, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'dockSizeChanged'
        QtMocHelpers::SignalData<void()>(3, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'exclusiveZoneChanged'
        QtMocHelpers::SignalData<void()>(4, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'layerShellReady'
        QtMocHelpers::SignalData<void()>(5, 2, QMC::AccessPublic, QMetaType::Void),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'edge'
        QtMocHelpers::PropertyData<enum Edge>(6, 0x80000000 | 7, QMC::DefaultPropertyFlags | QMC::Writable | QMC::EnumOrFlag | QMC::StdCppSet, 0),
        // property 'dockSize'
        QtMocHelpers::PropertyData<int>(8, QMetaType::Int, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 1),
        // property 'exclusiveZone'
        QtMocHelpers::PropertyData<int>(9, QMetaType::Int, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 2),
    };
    QtMocHelpers::UintData qt_enums {
        // enum 'Edge'
        QtMocHelpers::EnumData<enum Edge>(7, 7, QMC::EnumFlags{}).add({
            {   10, Edge::Top },
            {   11, Edge::Bottom },
            {   12, Edge::Left },
            {   13, Edge::Right },
        }),
    };
    return QtMocHelpers::metaObjectData<LayerShellWindow, qt_meta_tag_ZN16LayerShellWindowE_t>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums);
}
Q_CONSTINIT const QMetaObject LayerShellWindow::staticMetaObject = { {
    QMetaObject::SuperData::link<QQuickWindow::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN16LayerShellWindowE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN16LayerShellWindowE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN16LayerShellWindowE_t>.metaTypes,
    nullptr
} };

void LayerShellWindow::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<LayerShellWindow *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->edgeChanged(); break;
        case 1: _t->dockSizeChanged(); break;
        case 2: _t->exclusiveZoneChanged(); break;
        case 3: _t->layerShellReady(); break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (LayerShellWindow::*)()>(_a, &LayerShellWindow::edgeChanged, 0))
            return;
        if (QtMocHelpers::indexOfMethod<void (LayerShellWindow::*)()>(_a, &LayerShellWindow::dockSizeChanged, 1))
            return;
        if (QtMocHelpers::indexOfMethod<void (LayerShellWindow::*)()>(_a, &LayerShellWindow::exclusiveZoneChanged, 2))
            return;
        if (QtMocHelpers::indexOfMethod<void (LayerShellWindow::*)()>(_a, &LayerShellWindow::layerShellReady, 3))
            return;
    }
    if (_c == QMetaObject::ReadProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast<enum Edge*>(_v) = _t->edge(); break;
        case 1: *reinterpret_cast<int*>(_v) = _t->dockSize(); break;
        case 2: *reinterpret_cast<int*>(_v) = _t->exclusiveZone(); break;
        default: break;
        }
    }
    if (_c == QMetaObject::WriteProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: _t->setEdge(*reinterpret_cast<enum Edge*>(_v)); break;
        case 1: _t->setDockSize(*reinterpret_cast<int*>(_v)); break;
        case 2: _t->setExclusiveZone(*reinterpret_cast<int*>(_v)); break;
        default: break;
        }
    }
}

const QMetaObject *LayerShellWindow::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *LayerShellWindow::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN16LayerShellWindowE_t>.strings))
        return static_cast<void*>(this);
    return QQuickWindow::qt_metacast(_clname);
}

int LayerShellWindow::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QQuickWindow::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 4)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 4;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 4)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 4;
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
void LayerShellWindow::edgeChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}

// SIGNAL 1
void LayerShellWindow::dockSizeChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, nullptr);
}

// SIGNAL 2
void LayerShellWindow::exclusiveZoneChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 2, nullptr);
}

// SIGNAL 3
void LayerShellWindow::layerShellReady()
{
    QMetaObject::activate(this, &staticMetaObject, 3, nullptr);
}
QT_WARNING_POP
