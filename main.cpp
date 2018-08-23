/****************************************************************************
**
** Copyright (C) 2015 The Qt Company Ltd.
** Contact: http://www.qt.io/licensing/
**
** This file is part of the examples of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** You may use this file under the terms of the BSD license as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of The Qt Company Ltd nor the names of its
**     contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
****************************************************************************/

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QtCore/QTextStream>
#include <QtQuick/QQuickItem>
#include <QByteArray>
#include <QQuickPaintedItem>
#include <QBrush>
#include <QPainter>
#include <QDateTime>

class FPSText: public QQuickPaintedItem
{
    Q_OBJECT
    Q_PROPERTY(qreal fps READ fps NOTIFY fpsChanged)
    Q_PROPERTY(int timeWindow  MEMBER _timeWindow)
public:
    FPSText(QQuickItem *parent = 0);
    ~FPSText();
    void paint(QPainter *);
    Q_INVOKABLE qreal fps()const;

signals:
    void fpsChanged(int);

private:
    int _timeWindow;
    void recalculateFPS();
    qreal _currentFPS;
    int _cacheCount;
    QVector<qint64> _times;
};

FPSText::FPSText(QQuickItem *parent): QQuickPaintedItem(parent), _timeWindow(1000), _currentFPS(0), _cacheCount(0)
{
    _times.clear();
    setFlag(QQuickItem::ItemHasContents);
}

FPSText::~FPSText()
{
}

void FPSText::recalculateFPS()
{
    qint64 currentTime = QDateTime::currentDateTime().toMSecsSinceEpoch();
    _times.push_back(currentTime);

    while (_times.front() < currentTime - _timeWindow) {
        _times.pop_front();
    }

    int currentCount = _times.length();
    //_currentFPS = (currentCount + _cacheCount) / 2;
    _currentFPS = currentCount * (1000.0 / _timeWindow);
    //qDebug() << _currentFPS;

    if (currentCount != _cacheCount) fpsChanged(_currentFPS);

    _cacheCount = currentCount;
}

qreal FPSText::fps()const
{
    return _currentFPS;
}

void FPSText::paint(QPainter *painter)
{
    recalculateFPS();
    //qDebug() << __FUNCTION__;
    QBrush brush(Qt::transparent);

    painter->setBrush(brush);
    painter->setPen(Qt::NoPen);
    painter->setRenderHint(QPainter::Antialiasing);
    painter->drawRoundedRect(0, 0, boundingRect().width(), boundingRect().height(), 0, 0);
    update();
}




static bool parseArgs(QStringList& args, QVariantMap& parameters)
{

    while (!args.isEmpty()) {

        QString param = args.takeFirst();

        if (param.startsWith("--help")) {
            QTextStream out(stdout);
            out << "Usage: " << endl;
            out << "--plugin.<parameter_name> <parameter_value>    -  Sets parameter = value for plugin" << endl;
            out.flush();
            return true;
        }

        if (param.startsWith("--plugin.")) {

            param.remove(0, 9);

            if (args.isEmpty() || args.first().startsWith("--")) {
                parameters[param] = true;
            } else {

                QString value = args.takeFirst();

                if (value == "true" || value == "on" || value == "enabled") {
                    parameters[param] = true;
                } else if (value == "false" || value == "off"
                           || value == "disable") {
                    parameters[param] = false;
                } else {
                    parameters[param] = value;
                }
            }
        }
    }
    return false;
}

#include "main.moc"

int main(int argc, char *argv[])
{
    const QByteArray additionalLibraryPaths = qgetenv("QTLOCATION_EXTRA_LIBRARY_PATH");

    for (const QByteArray &p : additionalLibraryPaths.split(':'))
        QCoreApplication::addLibraryPath(QString(p));

    QGuiApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QGuiApplication app(argc, argv);

    QVariantMap parameters;
    QStringList args(QCoreApplication::arguments());

    QByteArray mapboxMapID = qgetenv("MAPBOX_MAP_ID");
    QByteArray mapboxAccessToken = qgetenv("MAPBOX_ACCESS_TOKEN");
    QByteArray hereAppID = qgetenv("HERE_APP_ID");
    QByteArray hereToken = qgetenv("HERE_TOKEN");

    if (!mapboxMapID.isEmpty())
        parameters["mapbox.map_id"] = QLatin1String(mapboxMapID.constData());
    if (!mapboxAccessToken.isEmpty())
        parameters["mapbox.access_token"] = QLatin1String(mapboxAccessToken.constData());
    if (!hereAppID.isEmpty())
        parameters["here.app_id"] = QLatin1String(hereAppID.constData());
    if (!hereToken.isEmpty())
        parameters["here.token"] = QLatin1String(hereToken.constData());

    parameters["mapbox.routing.use_mapbox_text_instructions"] = false;


    if (parseArgs(args, parameters))
        return 0;

    QQmlApplicationEngine engine;
    qmlRegisterType<FPSText>("FPSText", 1, 0, "FPSText");

    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));


    QObject *item = engine.rootObjects().first();
    Q_ASSERT(item);
    QMetaObject::invokeMethod(item, "initializePluginParameters",
                              Q_ARG(QVariant, QVariant::fromValue(parameters)));

    return app.exec();
}
