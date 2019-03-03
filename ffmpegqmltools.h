#ifndef FFMPEGQMLTOOLS_H
#define FFMPEGQMLTOOLS_H

#include "ffmpegtools.h"

#include <QJSValue>
#include <QObject>
#include <QVariantMap>

class FfmpegQmlToolsPrivate;
class FfmpegQmlTools : public FfmpegTools
{
    Q_OBJECT

    Q_PROPERTY(QString tempDirectory READ tempDirectory WRITE setTempDirectory NOTIFY tempDirectoryChanged)
public:
    explicit FfmpegQmlTools(QObject *parent = nullptr);

signals:
    void tempDirectoryChanged();

public slots:
    void cut(const QString &inputFile, qint32 from_ms, qint32 to_ms, const QString &outputFile, QJSValue callback, bool copy = true);
    void merge(const QStringList &inputFiles, const QString &outputFile, QJSValue callback);
    void convert(const QString &inputFile, const QSize &resolution, qint32 frameRate, const QString &codec, const QString &outputFile, QJSValue callback);
    void render(QVariantList renderList, const QSize &resolution, const qreal &frameRate, const QString &encoder, const QString &outputFile, QJSValue callback);
    void setMetaData(const QString &inputFile, QVariantMap metadata, const QString &outputFile, QJSValue callback);
    void getMetaData(const QString &inputFile, QJSValue callback);
    void getData(const QString &inputFile, QJSValue callback);
    void takeScreenshot(const QString &inputFile, qint32 capture_time, const QString &outputFile, QJSValue callback);

    void setTempDirectory(const QString &tempDir);
    QString tempDirectory() const;

private:
    FfmpegQmlToolsPrivate *p;
};

#endif // FFMPEGQMLTOOLS_H
