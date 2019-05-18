#define EXIT_COMMAND "b6f353bf-899c-4065-99e3-330e684ad237"
#define RESET_COMMAND "f2d95412-abe8-4f2e-b43a-11adacdf2d9d"

#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QCoreApplication>
#include <QProcess>
#include <QDateTime>
#include <QDebug>
#include <QTimer>
#include <QFile>
#include <QMessageBox>

#include <iostream>

#ifdef Q_OS_WIN
#include <windows.h>
#endif

#include "asemanapplication.h"
#include "ffmpegqmltools.h"

void handleCloseRequest(qint32 closeRequestCommand)
{
    switch(closeRequestCommand)
    {
    case 1:
        // Reload
        break;
    case 2:
#ifdef Q_OS_WIN
        std::cout << RESET_COMMAND << std::endl;
#else
        qDebug() << RESET_COMMAND;
#endif
        break;
    default:
#ifdef Q_OS_WIN
        std::cout << EXIT_COMMAND << std::endl;
#else
        qDebug() << EXIT_COMMAND;
#endif
        break;
    }
}

int main(int argc, char *argv[])
{
#ifdef Q_OS_WIN
    SetErrorMode(GetErrorMode () | SEM_NOGPFAULTERRORBOX);
#endif

    if(argc <= 1) {
        QCoreApplication app(argc, argv);

        QString instanceId = QString::number( QDateTime::currentDateTime().toSecsSinceEpoch() );
        bool allowQuit = false;
        bool reset = false;

        QProcess process;
#ifndef Q_OS_WIN
        process.setReadChannelMode(QProcess::ForwardedOutputChannel);
#endif

        auto callback = [&](QByteArray data){
            if(data.contains(EXIT_COMMAND))
                allowQuit = true;
            else
            if(data.contains(RESET_COMMAND))
                reset = true;
            else
                qDebug() << data.trimmed().toStdString().c_str();
        };

        process.connect(&process, &QProcess::readyReadStandardError, [&](){ callback(process.readAllStandardError()); });
        process.connect(&process, &QProcess::readyReadStandardOutput, [&](){ callback(process.readAllStandardOutput()); });
        process.connect(&process, static_cast<void(QProcess::*)(int)>(&QProcess::finished), [&](){
            if(allowQuit) {
                app.quit();
                QString cachePath = AsemanApplication::homePath() + "/cache/timeline/" + instanceId + ".cache";
                QFile::remove(cachePath);
            } else {
                if(reset) {
                    instanceId = QString::number( QDateTime::currentDateTime().toSecsSinceEpoch() );
                    qDebug() << "New instace generated";
                }

                allowQuit = false;
                reset = false;

                process.start(app.applicationFilePath(), {instanceId});
            }
        });

        process.start(app.applicationFilePath(), {instanceId});

        return app.exec();
    } else {
#ifdef Q_OS_WIN
        QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif
        qmlRegisterType<FfmpegQmlTools>("AsemanQml.Labs", 2, 0, "FfmpegTools");

        QApplication app(argc, argv);

        QString instanceId = app.arguments().at(1);

        QQmlApplicationEngine engine;
        engine.rootContext()->setContextProperty("instanceId", instanceId);
        engine.load(QUrl(QStringLiteral("qrc:/qml/main.qml")));
        if (engine.rootObjects().isEmpty())
            return -1;

        app.connect(&app, &QCoreApplication::aboutToQuit, [&](){
            const qint32 closeRequestCommand = engine.rootObjects().first()->property("closeRequestCommand").toInt();
            handleCloseRequest(closeRequestCommand);
        });

        qint32 ret = app.exec();

        const qint32 closeRequestCommand = engine.rootObjects().first()->property("closeRequestCommand").toInt();
        handleCloseRequest(closeRequestCommand);

        return ret;
    }
}
