#include <QAbstractListModel>
#include <QApplication>
#include <QDir>
#include <QFile>
#include <QProcess>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickItem>
#include <QQuickWindow>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QTest>
#include <Plasma/Applet>
#include <Plasma/Corona>
#include <Plasma/Containment>
#include <Plasma/PluginLoader>
#include <PlasmaQuick/AppletQuickItem>

class Windows : public QAbstractListModel {
    Q_OBJECT
public:
    using QAbstractListModel::QAbstractListModel;
    QStringList ids;
    const QStringList names{"Launch notes", "Project files", "Browser reference"};
    QHash<int, QByteArray> roleNames() const override {
        return {{Qt::DisplayRole,"display"},{Qt::DecorationRole,"decoration"},
                {256,"WinIdList"},{257,"AppName"},{258,"IsClosable"},{259,"IsExcludedFromCapture"}};
    }
    int rowCount(const QModelIndex &parent = {}) const override {return parent.isValid() ? 0 : ids.size();}
    QVariant data(const QModelIndex &index, int role) const override {
        if (!index.isValid() || index.row() >= ids.size()) return {};
        if (role == Qt::DisplayRole) return names[index.row() % names.size()];
        if (role == Qt::DecorationRole) return QStringLiteral("document-edit");
        if (role == 256) return QStringList{ids[index.row()]};
        if (role == 257) return QStringLiteral("Notes");
        if (role == 258) return true;
        if (role == 259) return false;
        return {};
    }
    void fill(int count) {
        beginResetModel(); ids.clear();
        for (int i = 0; i < count; ++i) ids << QString::number(i + 1);
        endResetModel();
    }
};

class Backend : public QObject {
    Q_OBJECT
    Q_PROPERTY(QAbstractItemModel *parked READ parked CONSTANT)
    Q_PROPERTY(QVariantList launcherEntries READ launcherEntries CONSTANT)
public:
    Windows windows;
    QString restored, closed, launched;
    QAbstractItemModel *parked() {return &windows;}
    QVariantList launcherEntries() const {
        return {QVariantMap{{"url","applications:files.desktop"},{"title","Files"},{"icon","system-file-manager"}},
                QVariantMap{{"url","applications:terminal.desktop"},{"title","Terminal"},{"icon","utilities-terminal"}},
                QVariantMap{{"url","applications:browser.desktop"},{"title","Browser"},{"icon","internet-web-browser"}}};
    }
    Q_INVOKABLE void restore(const QString &id) {restored = id;}
    Q_INVOKABLE void closeWindow(const QString &id) {closed = id;}
    Q_INVOKABLE void launch(const QString &url) {launched = url;}
Q_SIGNALS:
    void operationFailed(const QString &message);
};

class TestCorona : public Plasma::Corona {
public:
    QRect screenGeometry(uint) const override {return {0,0,1600,1000};}
};

class AppsTests : public QObject {
    Q_OBJECT
    const QString ui = QStringLiteral(SPATIAL_PLASMA_DIR) + "/apps/contents/ui";
    QStringList errors;
    QQuickItem *visualChild(QQuickItem *parent, const QString &name) {
        for (auto child : parent->childItems()) {
            if (child->objectName() == name) return child;
            if (auto found = visualChild(child, name)) return found;
        }
        return nullptr;
    }
    void captureErrors(QQmlEngine &engine) {
        connect(&engine, &QQmlEngine::warnings, this, [this](const QList<QQmlError> &warnings) {
            for (const auto &warning : warnings) errors << warning.toString();
        });
    }
private Q_SLOTS:
    void init() {errors.clear();}

    void wideViewRendersAndKeepsLaunchersFixed() {
        Backend backend; backend.windows.fill(30);
        QQmlApplicationEngine engine; captureErrors(engine);
        engine.rootContext()->setContextProperty("testBackend", &backend);
        engine.loadData((QStringLiteral("import QtQuick\nimport org.kde.kirigami as Kirigami\nimport \".\"\n") +
                         "Window { visible:true; width:280; height:900; color:Kirigami.Theme.backgroundColor;"
                         "AppsView { objectName:'apps'; anchors.fill:parent; backend:testBackend; previewsEnabled:false } }").toUtf8(), QUrl::fromLocalFile(ui + "/Harness.qml"));
        QVERIFY2(!engine.rootObjects().isEmpty(), qPrintable(errors.join('\n')));
        auto window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
        QVERIFY(window);
        QTest::qWait(100);
        auto apps = window->findChild<QQuickItem *>("apps");
        auto quick = window->findChild<QQuickItem *>("quickLaunch");
        auto list = window->findChild<QQuickItem *>("parkedList");
        QVERIFY(apps && quick && list);
        QCOMPARE(list->property("count").toInt(), 30);
        QVERIFY(list->height() > 500);
        auto launcher = visualChild(quick, "launcherButton");
        QVERIFY(launcher);
        QVERIFY(QMetaObject::invokeMethod(launcher, "clicked"));
        QCOMPARE(backend.launched, QStringLiteral("applications:files.desktop"));
        auto restore = visualChild(list, "restoreWindow");
        QVERIFY(restore);
        QVERIFY(QMetaObject::invokeMethod(restore, "clicked"));
        QCOMPARE(backend.restored, QStringLiteral("1"));
        const auto position = quick->mapToScene({0,0});
        list->setProperty("contentY", 450);
        QTest::qWait(30);
        QCOMPARE(quick->mapToScene({0,0}), position);
        QVERIFY(quick->height() >= 66);
        list->setProperty("contentY", 0);
        QTest::qWait(30);
        const auto screenshot = window->grabWindow();
        QVERIFY(!screenshot.isNull());
        QVERIFY(screenshot.save(QDir::currentPath() + "/apps-wide.png"));

        window->resize(220, 420);
        QTest::qWait(50);
        QVERIFY(list->height() >= 90);
        QVERIFY(list->mapToScene({0, list->height()}).y() <= window->height());
        QVERIFY2(errors.isEmpty(), qPrintable(errors.join('\n')));
    }

    void cardActionsUseTheWindowIdentity() {
        QQmlApplicationEngine engine; captureErrors(engine);
        engine.loadData((QStringLiteral("import QtQuick\nimport \".\"\n") +
                         "Window { visible:true; width:280; height:300; ParkedCard {"
                         "objectName:'card'; width:260; windowId:'window-two'; windowTitle:'Reference note'; previewsEnabled:false } }").toUtf8(), QUrl::fromLocalFile(ui + "/Harness.qml"));
        QVERIFY2(!engine.rootObjects().isEmpty(), qPrintable(errors.join('\n')));
        auto window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
        auto card = window->findChild<QQuickItem *>("card");
        QVERIFY(card);
        QSignalSpy restore(card, SIGNAL(restoreRequested(QString)));
        QSignalSpy close(card, SIGNAL(closeRequested(QString)));
        auto restoreButton = card->findChild<QQuickItem *>("restoreWindow");
        auto closeButton = card->findChild<QQuickItem *>("closeWindow");
        QVERIFY(restoreButton && closeButton);
        restoreButton->forceActiveFocus();
        QTest::keyClick(window, Qt::Key_Space);
        QCOMPARE(restore.count(), 1);
        QCOMPARE(restore.first().first().toString(), QStringLiteral("window-two"));
        QVERIFY(QMetaObject::invokeMethod(closeButton, "clicked"));
        QCOMPARE(close.count(), 1);
        QCOMPARE(close.first().first().toString(), QStringLiteral("window-two"));
        QVERIFY2(errors.isEmpty(), qPrintable(errors.join('\n')));
    }

    void nativeModelsAndPrivacyLoad() {
        QQmlApplicationEngine engine; captureErrors(engine);
        engine.load(QUrl::fromLocalFile(ui + "/WindowModel.qml"));
        QVERIFY2(!engine.rootObjects().isEmpty(), qPrintable(errors.join('\n')));
        auto model = engine.rootObjects().first();
        model->setProperty("launchers", QStringList{"preferred://filemanager", "applications:org.kde.konsole.desktop"});
        QTest::qWait(100);
        QVERIFY(model->property("parked").value<QObject *>());
        const auto launchers = model->property("launcherEntries").value<QJSValue>().toVariant().toList();
        QVERIFY2(!launchers.isEmpty(), "Native launcher model did not resolve installed applications");
        QQmlComponent preview(&engine, QUrl::fromLocalFile(ui + "/WindowPreview.qml"));
        std::unique_ptr<QObject> item(preview.createWithInitialProperties({{"windowId","private-window"},{"previewHidden",true}}));
        QVERIFY2(item, qPrintable(preview.errorString()));
        QCOMPARE(item->property("streamActive").toBool(), false);
        QCOMPARE(item->property("hasPreview").toBool(), false);
        QVERIFY2(errors.isEmpty(), qPrintable(errors.join('\n')));
    }

    void actualPlasmaPackageLoads() {
        const QString source = QStringLiteral(SPATIAL_PLASMA_DIR) + "/apps";
        QCOMPARE(QProcess::execute("kpackagetool6", {"--type","Plasma/Applet","--install",source}), 0);
        TestCorona corona;
        auto containment = corona.createContainment(QStringLiteral("null"));
        QVERIFY(containment);
        auto applet = containment->createApplet("org.xefensor.spatial.apps");
        QVERIFY(applet);
        auto item = PlasmaQuick::AppletQuickItem::itemForApplet(applet);
        QVERIFY(item);
        QQuickWindow window;
        item->setParentItem(window.contentItem());
        item->setSize({280,900});
        window.resize(280,900);
        window.show();
        QTRY_VERIFY_WITH_TIMEOUT(item->fullRepresentationItem(), 3000);
        QVERIFY(!applet->failedToLaunch());
        QVERIFY(item->fullRepresentationItem()->findChild<QQuickItem *>("parkedList"));
        item->setParentItem(nullptr);
    }
};

int main(int argc, char **argv) {
    QTemporaryDir data;
    qputenv("XDG_DATA_HOME", (data.path() + "/data").toUtf8());
    qputenv("XDG_CONFIG_HOME", (data.path() + "/config").toUtf8());
    QApplication app(argc, argv);
    app.setApplicationName("spatial-apps-checks");
    AppsTests tests;
    return QTest::qExec(&tests, argc, argv);
}

#include "test_apps.moc"
