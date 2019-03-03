#include "ffmpegtools.h"

#include <QTime>
#include <QDebug>
#include <QFile>
#include <QCoreApplication>
#include <QFileInfo>
#include <QDir>
#include <QPointer>
#include <QtAlgorithms>

FfmpegTools::FfmpegTools(QObject *parent) :
    QObject(parent)
{
    tempDirectory = QCoreApplication::applicationDirPath();
}

FfmpegTools::~FfmpegTools()
{

}

qreal FfmpegTools::getProgress(const QString &output, qint32 duration, qint32 from_ms = 0)
{
    QString time = "";
    qreal progress;

    QRegExp rx("time=(\\d\\d:\\d\\d:\\d\\d.\\d\\d)");
    int pos = rx.indexIn(output);
    if (pos > -1) {
        time = rx.cap(1);
    }
    if(time == "") {
        progress = -1;
    } else {
        QTime currentTime = QTime::fromString(time);
        qint32 currentTimeMs = QTime(0, 0, 0).msecsTo(currentTime) - from_ms;
        progress = currentTimeMs / static_cast<qreal>(duration);
    }
    if(progress >= 1)
        progress = 0.99999;

    return progress;
}

QString FfmpegTools::fileSuffix(const QString &path)
{
    QString res = path.mid(path.lastIndexOf("."));
    return res;
}

qint32 FfmpegTools::getRemainingTime(ProcessStatus processStatus, qreal progress)
{
    // fix compare issue with float
    if(processStatus.lastProgress == 0.0) {
        return -1;
    }
    qreal averageSpeed = progress / processStatus.startTime.msecsTo(QTime::currentTime());
    qreal speed = (progress - processStatus.lastProgress) / processStatus.lastTime.msecsTo(QTime::currentTime());
    qreal overallSpeed = ( averageSpeed + speed ) / 2;
    qint32 remainingTime = static_cast<qint32>(( 1 - progress ) / overallSpeed);
//    qint32 timeDiff = processStatus.lastTime.msecsTo(QTime::currentTime());
//    qreal progressRatio = (1 - processStatus.lastProgress) / (progress - processStatus.lastProgress);
//    qint32 remainingTime = timeDiff * progressRatio - timeDiff;
    return remainingTime;
}

void FfmpegTools::cutAndConvert(const QString &inputFile, qint32 from_ms, qint32 to_ms, const QSize &resolution, qreal frameRate, const QString &_encoder, const QString &outputFile, std::function<void (qreal, const QString &, qint32)> callback)
{
    getData(inputFile, [=](Metadata metadata){
        QPointer<QProcess> ffmpegProcess = new QProcess(this);
        qreal fps;
        if(frameRate == 0.0) {
            fps = metadata.fps;
        } else {
            fps = frameRate;
        }

        QTime startTime(0, 0);
        QTime endTime(0, 0);
        startTime = startTime.addMSecs(from_ms);
        endTime = endTime.addMSecs(to_ms - from_ms);
        qint32 duration = to_ms - from_ms;

        QString encoder = (_encoder.isEmpty()? "libx264" : _encoder);

        QStringList options = {"-y",  "-ss", startTime.toString("HH:mm:s.zzz"), "-i", inputFile, "-to", endTime.toString("HH:mm:s.zzz"), "-c:a", "aac", "-ar", "48000", "-b:a", "160k", "-c:v", encoder, "-r", QString::number(fps), "-vf", "scale=" + QString::number(resolution.width()) + ":" + QString::number(resolution.height()), "-strict", "experimental", "-preset", "ultrafast", outputFile, "-avoid_negative_ts", "make_zero", "-hide_banner"};
        ffmpegProcess->start(QStringLiteral("ffmpeg"), options);
        qDebug() << options;

        processStatus[ffmpegProcess].startTime = QTime::currentTime();
        processStatus[ffmpegProcess].lastProgress = 0;

        connect(ffmpegProcess, &QProcess::readyReadStandardOutput, [=](){
            QByteArray output = ffmpegProcess->readAllStandardOutput();
            qreal progress = getProgress(output, duration);
            qDebug() << output.toStdString().c_str();
            if(progress == -1)
                return;

            qint32 remainingTime = getRemainingTime(processStatus.value(ffmpegProcess), progress);

            processStatus[ffmpegProcess].lastTime = QTime::currentTime();
            processStatus[ffmpegProcess].lastProgress = progress;

            callback(progress, output, remainingTime);
        });

        connect(ffmpegProcess, &QProcess::readyReadStandardError, [=](){
            QString output = ffmpegProcess->readAllStandardError();
            qreal progress = getProgress(output, duration);
            qDebug() << output.toStdString().c_str();
            if(progress == -1)
                return;

            qint32 remainingTime = getRemainingTime(processStatus.value(ffmpegProcess), progress);

            processStatus[ffmpegProcess].lastTime = QTime::currentTime();
            processStatus[ffmpegProcess].lastProgress = progress;

            callback(progress, output, remainingTime);
        });

        connect(ffmpegProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, [=](int exitCode, QProcess::ExitStatus exitStatus){
            if(!ffmpegProcess)
                return;

            callback(1, "exitCode:" + QString::number(exitCode) + " exitStatus:" + exitStatus, 10);
            ffmpegProcess->deleteLater();
        }, Qt::QueuedConnection);
    });
}

void FfmpegTools::cut(const QString &inputFile, qint32 from_ms, qint32 to_ms, const QString &outputFile, std::function<void (qreal, const QString &, qint32)> callback, bool copy)
{
    QPointer<QProcess> ffmpegProcess = new QProcess(this);

    QTime startTime(0, 0);
    QTime endTime(0, 0);
    startTime = startTime.addMSecs(from_ms);
    endTime = endTime.addMSecs(to_ms - from_ms);
    qint32 duration = to_ms - from_ms;

    QStringList options = {"-y",  "-ss", startTime.toString("HH:mm:s.zzz"), "-i", inputFile, "-to", endTime.toString("HH:mm:s.zzz"), outputFile, "-avoid_negative_ts", "make_zero", "-hide_banner"};
    if(copy) {
        options.insert(7, "-c");
        options.insert(8, "copy");
    }
    qDebug()  << options;
    ffmpegProcess->start(QStringLiteral("ffmpeg"), options);

    processStatus[ffmpegProcess].startTime = QTime::currentTime();
    processStatus[ffmpegProcess].lastProgress = 0;

    connect(ffmpegProcess, &QProcess::readyReadStandardOutput, [=](){
        QByteArray output = ffmpegProcess->readAllStandardOutput();
        qreal progress = getProgress(output, duration);
        qDebug() << output.toStdString().c_str();
        if(progress == -1)
            return;

        qint32 remainingTime = getRemainingTime(processStatus.value(ffmpegProcess), progress);

        processStatus[ffmpegProcess].lastTime = QTime::currentTime();
        processStatus[ffmpegProcess].lastProgress = progress;

        callback(progress, output, remainingTime);
    });

    connect(ffmpegProcess, &QProcess::readyReadStandardError, [=](){
        QString output = ffmpegProcess->readAllStandardError();
        qreal progress = getProgress(output, duration);
        qDebug() << output.toStdString().c_str();
        if(progress == -1)
            return;

        qint32 remainingTime = getRemainingTime(processStatus.value(ffmpegProcess), progress);

        processStatus[ffmpegProcess].lastTime = QTime::currentTime();
        processStatus[ffmpegProcess].lastProgress = progress;

        callback(progress, output, remainingTime);
    });

    connect(ffmpegProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, [=](int exitCode, QProcess::ExitStatus exitStatus){
        if(!ffmpegProcess)
            return;

        callback(1, "exitCode:" + QString::number(exitCode) + " exitStatus:" + exitStatus, 10);
        ffmpegProcess->deleteLater();
    }, Qt::QueuedConnection);
}

void FfmpegTools::merge(const QStringList &inputFiles, const QString &outputFile, std::function<void (qreal, const QString &, qint32)> callback)
{
    QFile::remove(tempDirectory + "/list");
	
    int *jobs = new int(0);
    QList<Metadata> *metas = new QList<Metadata>();
    for(const auto &file: inputFiles) {
        getData(file, [jobs, metas, this, inputFiles, outputFile, callback](Metadata metadata) {
            metas->append(metadata);
            (*jobs)--;
            if(*jobs == 0) {
                qint32 totalDuration = 0;
                for(int i = 0; i < metas->size(); i++) {
                    totalDuration += metas->at(i).duration;
                }
                QFile file(tempDirectory + "/list");
                file.open(QIODevice::ReadWrite);
                for(const auto &fileName: inputFiles) {
                    QString text = "file '" + fileName + "'\n";
                    file.write(text.toUtf8());
                }
                file.close();

                QPointer<QProcess> ffmpegProcess = new QProcess(this);
                ffmpegProcess->setWorkingDirectory(tempDirectory);

                QStringList options = {"-y", "-f", "concat", "-safe", "0", "-i", "list", "-c", "copy", outputFile, "-hide_banner"};

                qDebug() << __LINE__ << __FUNCTION__ << options;

                ffmpegProcess->start(QStringLiteral("ffmpeg"), options);

                processStatus[ffmpegProcess].startTime = QTime::currentTime();
                processStatus[ffmpegProcess].lastProgress = 0;

                connect(ffmpegProcess, &QProcess::readyReadStandardOutput, [=](){
                    QByteArray output = ffmpegProcess->readAllStandardOutput();
                    qreal progress = getProgress(output, totalDuration);
                    qDebug() << output.toStdString().c_str();

                    qint32 remainingTime = getRemainingTime(processStatus.value(ffmpegProcess), progress);

                    processStatus[ffmpegProcess].lastTime = QTime::currentTime();
                    processStatus[ffmpegProcess].lastProgress = progress;

                    callback(progress, output, remainingTime);
                });

                connect(ffmpegProcess, &QProcess::readyReadStandardError, [=](){
                    QString output = ffmpegProcess->readAllStandardError();
                    qreal progress = getProgress(output, totalDuration);
                    qDebug() << output.toStdString().c_str();

                    qint32 remainingTime = getRemainingTime(processStatus.value(ffmpegProcess), progress);

                    processStatus[ffmpegProcess].lastTime = QTime::currentTime();
                    processStatus[ffmpegProcess].lastProgress = progress;

                    callback(progress, output, remainingTime);
                });

                connect(ffmpegProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, [=](int exitCode, QProcess::ExitStatus exitStatus){
                    if(ffmpegProcess) {
                        callback(1, "exitCode:" + QString::number(exitCode) + " exitStatus:" + exitStatus, 10);
                        ffmpegProcess->deleteLater();
                    }

                    QFile::remove(tempDirectory + "/list");

                    // problem with fastcut and render if used together fix this
                    QDir dir(tempDirectory + "/temp");
                    dir.removeRecursively();

                    delete jobs;
                    delete metas;
                }, Qt::QueuedConnection);
            }
        });
        (*jobs)++;
    }
}

void FfmpegTools::convert(const QString &inputFile, const QSize &resolution, qreal frameRate, const QString &codec, const QString &outputFile, std::function<void (qreal, const QString &, qint32)> callback)
{
    getData(inputFile, [=](Metadata metadata){
        QPointer<QProcess> ffmpegProcess = new QProcess(this);
        qreal fps;
        if(frameRate == 0.0) {
            fps = metadata.fps;
        } else {
            fps = frameRate;
        }

        QStringList options = {"-y",  "-i", inputFile, "-c:a", "aac", "-ar", "48000", "-b:a", "160k", "-c:v", codec, "-r", QString::number(fps), "-vf", "scale=" + QString::number(resolution.width()) + ":" + QString::number(resolution.height()), "-strict", "experimental", outputFile};
        ffmpegProcess->start(QStringLiteral("ffmpeg"), options);

        qDebug() << __LINE__ << __FUNCTION__ << options;

        processStatus[ffmpegProcess].startTime = QTime::currentTime();
        processStatus[ffmpegProcess].lastProgress = 0;

        connect(ffmpegProcess, &QProcess::readyReadStandardOutput, [=](){
            QByteArray output = ffmpegProcess->readAllStandardOutput();
            qreal progress = getProgress(output, metadata.duration);

            qDebug() << output.toStdString().c_str();

            qint32 remainingTime = getRemainingTime(processStatus.value(ffmpegProcess), progress);

            processStatus[ffmpegProcess].lastTime = QTime::currentTime();
            processStatus[ffmpegProcess].lastProgress = progress;

            callback(progress , output, remainingTime);
        });

        connect(ffmpegProcess, &QProcess::readyReadStandardError, [=](){
            QString output = ffmpegProcess->readAllStandardError();
            qreal progress = getProgress(output, metadata.duration);

            qDebug() << output.toStdString().c_str();

            qint32 remainingTime = getRemainingTime(processStatus.value(ffmpegProcess), progress);

            processStatus[ffmpegProcess].lastTime = QTime::currentTime();
            processStatus[ffmpegProcess].lastProgress = progress;

            callback(progress, output, remainingTime);
        });

        connect(ffmpegProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, [=](int exitCode, QProcess::ExitStatus exitStatus){
            if(!ffmpegProcess)
                return;

            callback(1, "exitCode:" + QString::number(exitCode) + " exitStatus:" + exitStatus, 10);
            ffmpegProcess->deleteLater();
        }, Qt::QueuedConnection);
    });
}

void FfmpegTools::getData(const QString &inputFile, std::function<void (Metadata)> callback)
{
    QPointer<QProcess> ffmpegProcess = new QProcess(this);
    QStringList options = {"-y", "-i", inputFile, "-hide_banner"};
    ffmpegProcess->start(QStringLiteral("ffmpeg"), options);

    connect(ffmpegProcess, &QProcess::readyReadStandardOutput, this, [ffmpegProcess, this](){
        buffers[ffmpegProcess] += ffmpegProcess->readAllStandardOutput();
    });

    connect(ffmpegProcess, &QProcess::readyReadStandardError, this, [=](){
        buffers[ffmpegProcess] += ffmpegProcess->readAllStandardError();
    });

    connect(ffmpegProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, [ffmpegProcess, this, callback](){
        if(!ffmpegProcess)
            return ;

        QByteArray output = buffers.value(ffmpegProcess);
        Metadata metadata;
        QRegExp rx("Duration:\\s(\\d\\d:\\d\\d:\\d\\d.\\d\\d).+Video:\\s([^\\s]+).+\\,\\s(\\d+)x(\\d+).+(\\d+\\.*\\d*)\\s+fps");
        int pos = rx.indexIn(output);
        if(pos > -1) {
            QTime time(0, 0);
            metadata.duration = QTime(0, 0, 0).msecsTo(QTime::fromString(rx.cap(1)));
            metadata.codec = rx.cap(2);
            metadata.resolution = QSize(rx.cap(3).toInt(), rx.cap(4).toInt());
            metadata.fps = rx.cap(5).toDouble();
        } else {
            metadata.duration = -1;
            metadata.resolution = QSize(-1, -1);
            metadata.fps = -1;
        }
        callback(metadata);
        ffmpegProcess->deleteLater();
    }, Qt::QueuedConnection);

    connect(ffmpegProcess, &QProcess::destroyed, this, [ffmpegProcess, this](){
       buffers.remove(ffmpegProcess);
    });
}

void FfmpegTools::render(QList<FfmpegTools::Render> renderList, const QSize &resolution, qreal frameRate, const QString &encoder, const QString &outputFile, std::function<void (qreal, const QString &, qint32)> callback)
{
    qDebug() << __LINE__ << __FUNCTION__ << "There are" << renderList.count() << "item to render"
             << "Resolutin=" << resolution
             << "FrameRate=" << frameRate
             << "Encoder=" << encoder
             << "OutPut=" << outputFile;

    QDir dir(tempDirectory + "/temp");
    dir.removeRecursively();
    qreal *totalProgress = new qreal(0);
    const qreal singleProgress = 1.0 / renderList.length();
    auto topCallback = [callback, totalProgress, singleProgress](qreal progress, const QString &log, qint32 remainingTime) {
        if(progress == -1)
            return;
        qreal newProgress = progress * singleProgress;
        callback(*totalProgress + newProgress, log, remainingTime);
        if(progress == 1) {
            *totalProgress += singleProgress;
        }
    };
    QDir dir2;
    dir2.mkpath(tempDirectory + "/temp/cut");
    qDebug() << __LINE__ << __FUNCTION__ << "Dir created:" << tempDirectory + "/temp/cut";

    int *jobs = new int(0);
    QHash<QString, FfmpegTools::Metadata> *renderListData = new QHash<QString, FfmpegTools::Metadata>();
    for(const auto &renderItem: renderList) {
        getData(renderItem.inputFile, [outputFile, resolution, renderList, topCallback, this, jobs, renderItem, renderListData, frameRate, encoder](FfmpegTools::Metadata metadata) {
            (*jobs)--;
            if(frameRate > 0)
                metadata.fps = frameRate;

            renderListData->insert(renderItem.inputFile, metadata);
            if(*jobs == 0) {
                QHashIterator<QString, FfmpegTools::Metadata> i(*renderListData);
                qreal minFps = 480;
                QList<FfmpegTools::Metadata> metas = renderListData->values();
                for(FfmpegTools::Metadata m: metas)
                    if(m.fps < minFps)
                        minFps = m.fps;

                while(i.hasNext()) {
                    i.next();
                    FfmpegTools::Metadata meta = i.value();
                    meta.fps = minFps;
                    (*renderListData)[i.key()] = meta;
                }

                delete jobs;
                render_cut(outputFile, renderList, renderList, resolution, encoder, *renderListData, topCallback);
            }
        });
        (*jobs)++;
    }
}

void FfmpegTools::takeScreenshot(const QString &inputFile, qint32 capture_time, const QString &outputFile, std::function<void (const QString &log)> callback)
{
    QTime time(0, 0);
    time = time.addMSecs(capture_time);

    QPointer<QProcess> ffmpegProcess = new QProcess(this);
    QStringList options = {"-y", "-ss", time.toString("HH:mm:s.zzz"),"-i", inputFile, outputFile,"-hide_banner"};
    ffmpegProcess->start(QStringLiteral("ffmpeg"), options);

    connect(ffmpegProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, [ffmpegProcess, callback](){
        if(!ffmpegProcess)
            return;

        callback(ffmpegProcess->readAllStandardOutput());
        ffmpegProcess->deleteLater();
    }, Qt::QueuedConnection);
}

void FfmpegTools::setTempDirectory(const QString &tempDir)
{
    tempDirectory = tempDir;
}

QString FfmpegTools::getTempDirectory() const
{
    return tempDirectory;
}

void FfmpegTools::render_cut(const QString &outputFile, const QList<FfmpegTools::Render> renderListCopy, QList<FfmpegTools::Render> renderList, const QSize &resolution, const QString &encoder, const QHash<QString, FfmpegTools::Metadata> &renderListData, std::function<void (qreal, const QString &, qint32)> callback, qint32 nameKey)
{
    QString suffix = fileSuffix(outputFile);

    if(renderList.isEmpty()) {
        QStringList inputFiles;
        for(int i = 0; i < renderListCopy.size(); i++) {
            inputFiles.append(tempDirectory + "/temp/cut/" + QString::number(i) + (suffix.isEmpty()? fileSuffix(renderListCopy.at(i).inputFile) : suffix));
        }
        merge(inputFiles, outputFile, callback);
        return;
    }

    Render renderItem = renderList.takeFirst();
    if(renderItem.startTime == 0 && renderItem.endTime == 0) {
        renderItem.startTime = 0;
        renderItem.endTime = renderListData[renderItem.inputFile].duration;
    }

    if(encoder.isEmpty()) {
        qDebug() << __LINE__ << __FUNCTION__ << "Encoder is empty, so we decided to use cut only method.";
        cut(renderItem.inputFile, renderItem.startTime, renderItem.endTime, tempDirectory + "/temp/cut/" + QString::number(nameKey) + (suffix.isEmpty()? fileSuffix(renderItem.inputFile) : suffix), [=](qreal progress, const QString &log, qint32 remainingTime){
            callback(progress, log, remainingTime);
            if(progress == 1.0) {
                render_cut(outputFile, renderListCopy, renderList, resolution, encoder, renderListData, callback, nameKey + 1);
            }
        });
    } else {
        qDebug() << __LINE__ << __FUNCTION__ << QString("Encoder is %1, so we decided to use cut only method.").arg(encoder).toStdString().c_str();
        cutAndConvert(renderItem.inputFile, renderItem.startTime, renderItem.endTime,
                      resolution, renderListData.value(renderItem.inputFile).fps, encoder,
                      tempDirectory + "/temp/cut/" + QString::number(nameKey) + (suffix.isEmpty()? fileSuffix(renderItem.inputFile) : suffix),
                      [=](qreal progress, const QString &log, qint32 remainingTime) {
            callback(progress, log, remainingTime);
            if(progress == 1.0) {
                render_cut(outputFile, renderListCopy, renderList, resolution, encoder, renderListData, callback, nameKey + 1);
            }
        });
    }

}

void FfmpegTools::setMetaData(const QString &inputFile, QHash<QString, QString> metadata, const QString &outputFile, std::function<void (qreal, const QString &, qint32)> callback)
{
    QStringList metadataList;
    QHashIterator<QString, QString> i(metadata);
    while(i.hasNext()) {
        i.next();
        metadataList << "-metadata";
        metadataList << i.key() + "=" + i.value();
    }
    getData(inputFile, [=](Metadata metadata){
        QPointer<QProcess> ffmpegProcess = new QProcess(this);
        QStringList options = {"-y",  "-i", inputFile, "-c", "copy"};
        options.append(metadataList);
        options.append(outputFile);
        ffmpegProcess->start(QStringLiteral("ffmpeg"), options);

        processStatus[ffmpegProcess].startTime = QTime::currentTime();
        processStatus[ffmpegProcess].lastProgress = 0;

        connect(ffmpegProcess, &QProcess::readyReadStandardOutput, [=](){
            QByteArray output = ffmpegProcess->readAllStandardOutput();
            qreal progress = getProgress(output, metadata.duration);

            qint32 remainingTime = getRemainingTime(processStatus.value(ffmpegProcess), progress);

            processStatus[ffmpegProcess].lastTime = QTime::currentTime();
            processStatus[ffmpegProcess].lastProgress = progress;

            callback(progress , output, remainingTime);
        });

        connect(ffmpegProcess, &QProcess::readyReadStandardError, [=](){
            QString output = ffmpegProcess->readAllStandardError();
            qreal progress = getProgress(output, metadata.duration);

            qint32 remainingTime = getRemainingTime(processStatus.value(ffmpegProcess), progress);

            processStatus[ffmpegProcess].lastTime = QTime::currentTime();
            processStatus[ffmpegProcess].lastProgress = progress;

            callback(progress, output, remainingTime);
        });

        connect(ffmpegProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, [=](int exitCode, QProcess::ExitStatus exitStatus){
            if(!ffmpegProcess)
                return;

            callback(1, "exitCode:" + QString::number(exitCode) + " exitStatus:" + exitStatus, 10);
            ffmpegProcess->deleteLater();
        }, Qt::QueuedConnection);
    });
}

void FfmpegTools::getMetaData(const QString &inputFile, std::function<void (QHash<QString, QString>)> callback)
{
    QPointer<QProcess> ffmpegProcess = new QProcess(this);
    QStringList options = {"-y", "-i", inputFile, "-hide_banner"};
    ffmpegProcess->start(QStringLiteral("ffmpeg"), options);

    connect(ffmpegProcess, &QProcess::readyReadStandardOutput, this, [ffmpegProcess, this](){
        buffers[ffmpegProcess] += ffmpegProcess->readAllStandardOutput();
    });

    connect(ffmpegProcess, &QProcess::readyReadStandardError, this, [=](){
        buffers[ffmpegProcess] += ffmpegProcess->readAllStandardError();
    });

    connect(ffmpegProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, [ffmpegProcess, this, callback](){
        if(!ffmpegProcess)
            return;

        QByteArray output = buffers.value(ffmpegProcess);
        QHash<QString, QString> metadata;
        QRegExp rx("([^\\s]+)\\s+:\\s([^\\s]+)");
        int pos = 0;
        while((pos = rx.indexIn(output, pos)) != -1) {
            metadata.insert(rx.cap(1), rx.cap(2));
            pos += rx.matchedLength();
        }
        callback(metadata);
        ffmpegProcess->deleteLater();
    }, Qt::QueuedConnection);

    connect(ffmpegProcess, &QProcess::destroyed, this, [ffmpegProcess, this](){
       buffers.remove(ffmpegProcess);
    });
}
