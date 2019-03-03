#ifndef FFMPEGTOOLS_H
#define FFMPEGTOOLS_H

#include <QObject>
#include <functional>
#include <QProcess>
#include <QSize>
#include <QTime>

class FfmpegTools: public QObject
{
    Q_OBJECT
public:
    struct Metadata {
        qint32 duration;
        QString codec;
        qreal fps;
        QSize resolution;
    };

    struct Render {
        QString inputFile;
        qint32 startTime;
        qint32 endTime;
    };

    FfmpegTools(QObject *parent = Q_NULLPTR);
    virtual ~FfmpegTools();

public:
    void cutAndConvert(const QString &inputFile, qint32 from_ms, qint32 to_ms, const QSize &resolution, qreal frameRate, const QString &_encoder, const QString &outputFile, std::function<void (qreal, const QString &, qint32)> callback);
    void cut(const QString &inputFile, qint32 from_ms, qint32 to_ms, const QString &outputFile, std::function<void (qreal progress, const QString &log, qint32 remainingTime)> callback, bool copy = true);
    void merge(const QStringList &inputFiles, const QString &outputFile, std::function<void (qreal progress, const QString &log, qint32 remainingTime)> callback);
    void convert(const QString &inputFile, const QSize &resolution, qreal frameRate, const QString &codec, const QString &outputFile, std::function<void (qreal progress, const QString &log, qint32 remainingTime)> callback);
    void setMetaData(const QString &inputFile, QHash<QString, QString> metadata, const QString &outputFile, std::function<void (qreal progress, const QString &log, qint32 remainingTime)> callback);
    void getMetaData(const QString &inputFile, std::function<void (QHash<QString, QString> metadata)> callback);
    void getData(const QString &inputFile, std::function<void (Metadata metadata)> callback);
    void render(QList<Render> renderList, const QSize &resolution, qreal frameRate, const QString &encoder, const QString &outputFile, std::function<void (qreal progress, const QString &log, qint32 remainingTime)> callback);
    void takeScreenshot(const QString &inputFile, qint32 capture_time, const QString &outputFile, std::function<void (const QString &log)> callback);

    void setTempDirectory(const QString &tempDir);
    QString getTempDirectory() const;

private:
    struct ProcessStatus {
        QTime startTime;
        QTime lastTime;
        qreal lastProgress;
    };

    QString tempDirectory;

    QHash<QProcess*, QByteArray> buffers;
    QHash<QProcess*, ProcessStatus> processStatus;
    qreal getProgress(const QString &output, qint32 duration, qint32 from_ms);
    QString fileSuffix(const QString &path);
    qint32 getRemainingTime(ProcessStatus lastStatus, qreal progress);
    void render_cut(const QString &outputFile, const QList<Render> renderListCopy, QList<Render> renderList, const QSize &resolution, const QString &encoder, const QHash<QString, FfmpegTools::Metadata> &renderListData, std::function<void (qreal progress, const QString &log, qint32 remainingTime)> callback, qint32 nameKey = 0);
};

#endif // FFMPEGTOOLS_H
