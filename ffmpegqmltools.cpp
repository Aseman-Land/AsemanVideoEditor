#include "ffmpegqmltools.h"

#include <QQmlEngine>

class FfmpegQmlToolsPrivate {
public:
    QString tempDirectory;
};

FfmpegQmlTools::FfmpegQmlTools(QObject *parent) : FfmpegTools(parent)
{
    p = new FfmpegQmlToolsPrivate;
}

void FfmpegQmlTools::cut(const QString &inputFile, qint32 from_ms, qint32 to_ms, const QString &outputFile, QJSValue callback, bool copy)
{
    FfmpegTools::cut(inputFile, from_ms, to_ms, outputFile, [callback](qreal progress, const QString &log, qint32 remainingTime){
        QJSValueList args;
        args << progress << log << remainingTime;

        QJSValue _callback(callback);
        _callback.call(args);
    }, copy);
}

void FfmpegQmlTools::merge(const QStringList &inputFiles, const QString &outputFile, QJSValue callback)
{
    FfmpegTools::merge(inputFiles, outputFile, [callback](qreal progress, const QString &log, qint32 remainingTime){
        QJSValueList args;
        args << progress << log << remainingTime;

        QJSValue _callback(callback);
        _callback.call(args);
    });
}

void FfmpegQmlTools::convert(const QString &inputFile, const QSize &resolution, qint32 frameRate, const QString &codec, const QString &outputFile, QJSValue callback)
{
    FfmpegTools::convert(inputFile, resolution, frameRate, codec, outputFile, [callback](qreal progress, const QString &log, qint32 remainingTime){
        QJSValueList args;
        args << progress << log << remainingTime;

        QJSValue _callback(callback);
        _callback.call(args);
    });
}

void FfmpegQmlTools::render(QVariantList _renderList, const QSize &resolution, const qreal &frameRate, const QString &encoder, const QString &outputFile, QJSValue callback)
{
    QList<Render> renderlist;
    for(const QVariant &item: _renderList) {
        QMap<QString, QVariant> renderMap = item.toMap();
        FfmpegTools::Render render;
        render.inputFile = renderMap["inputFile"].toString();
        render.startTime = renderMap["startTime"].toInt();
        render.endTime = renderMap["endTime"].toInt();
        renderlist.append(render);
    }
    FfmpegTools::render(renderlist, resolution, frameRate, encoder, outputFile, [callback](qreal progress, const QString &log, qint32 remainingTime) {
        QJSValueList args;
        args << progress << log << remainingTime;

        QJSValue _callback(callback);
        _callback.call(args);
    });
}

void FfmpegQmlTools::setMetaData(const QString &inputFile, QVariantMap metadata, const QString &outputFile, QJSValue callback)
{
    QHash<QString, QString> qhashMetadata;
    QMapIterator<QString, QVariant> i(metadata);
    while (i.hasNext()) {
        i.next();
        qhashMetadata.insert(i.key(), i.value().toString());
    }
    FfmpegTools::setMetaData(inputFile, qhashMetadata, outputFile, [callback](qreal progress, const QString &log, qint32 remainingTime){
        QJSValueList args;
        args << progress << log << remainingTime;

        QJSValue _callback(callback);
        _callback.call(args);
    });
}

void FfmpegQmlTools::getMetaData(const QString &inputFile, QJSValue callback)
{
    FfmpegTools::getMetaData(inputFile, [this, callback](QHash<QString, QString> metadata){
       QVariantMap qvariantmapMetadata;
       QHashIterator<QString, QString> i(metadata);
       while (i.hasNext()) {
           i.next();
           qvariantmapMetadata.insert(i.key(), QVariant::fromValue(i.value()));
       }
       QVariant qvariantMetadata = QVariant::fromValue<QVariantMap>(qvariantmapMetadata);

       QQmlEngine *engine = qmlEngine(this);

       if(!engine)
           return;

       QJSValueList args;
       args << engine->toScriptValue(qvariantMetadata);

       QJSValue _callback(callback);
       _callback.call(args);
    });
}

void FfmpegQmlTools::getData(const QString &inputFile, QJSValue callback)
{
    FfmpegTools::getData(inputFile, [this, callback](Metadata metadata){
        QVariantMap mapMetadata;
        mapMetadata["duration"] = QVariant::fromValue(metadata.duration);
        mapMetadata["fps"] = QVariant::fromValue(metadata.fps);
        mapMetadata["codec"] = QVariant::fromValue(metadata.codec);
        mapMetadata["resolution"] = QVariant::fromValue(metadata.resolution);

        QVariant varMetadata(mapMetadata);

        QQmlEngine *engine = qmlEngine(this);

        if(!engine)
            return;

        QJSValueList args;
        args << engine->toScriptValue(varMetadata);

        QJSValue _callback(callback);
        _callback.call(args);
    });
}

void FfmpegQmlTools::takeScreenshot(const QString &inputFile, qint32 capture_time, const QString &outputFile, QJSValue callback)
{
    FfmpegTools::takeScreenshot(inputFile, capture_time, outputFile, [callback](const QString &log){
        QJSValueList args;
        args << log;

        QJSValue _callback = callback;
        _callback.call(args);
    });
}

void FfmpegQmlTools::setTempDirectory(const QString &tempDir)
{
    if(p->tempDirectory == tempDir)
        return;

    p->tempDirectory = tempDir;
    Q_EMIT tempDirectoryChanged();
    FfmpegTools::setTempDirectory(tempDir);
}

QString FfmpegQmlTools::tempDirectory() const
{
    return p->tempDirectory;
}
