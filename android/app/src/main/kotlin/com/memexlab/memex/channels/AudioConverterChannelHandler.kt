package com.memexlab.memex.channels

import android.app.Activity
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedOutputStream
import java.io.FileOutputStream
import java.io.RandomAccessFile
import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * Handles `com.memexlab.memex/audio_converter` MethodChannel.
 * Converts any audio file to WAV 16 kHz mono using MediaCodec.
 */
class AudioConverterChannelHandler {

    companion object {
        private const val CHANNEL = "com.memexlab.memex/audio_converter"
        private const val TARGET_RATE = 16000
        private const val WAV_HEADER_SIZE = 44

        fun register(flutterEngine: FlutterEngine, activity: Activity) {
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                .setMethodCallHandler { call, result ->
                    when (call.method) {
                        "convertToWav" -> {
                            val inputPath = call.argument<String>("inputPath")
                            val outputPath = call.argument<String>("outputPath")
                            if (inputPath == null || outputPath == null) {
                                result.error("INVALID_ARGUMENTS", "Missing inputPath or outputPath", null)
                                return@setMethodCallHandler
                            }
                            Thread {
                                try {
                                    convertToWav(inputPath, outputPath)
                                    activity.runOnUiThread { result.success(outputPath) }
                                } catch (e: Exception) {
                                    activity.runOnUiThread { result.error("CONVERT_ERROR", e.message, null) }
                                }
                            }.start()
                        }
                        else -> result.notImplemented()
                    }
                }
        }

        // -- Audio conversion logic --

        private fun convertToWav(inputPath: String, outputPath: String) {
            val extractor = MediaExtractor()
            extractor.setDataSource(inputPath)

            var audioTrackIndex = -1
            for (i in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: ""
                if (mime.startsWith("audio/")) {
                    audioTrackIndex = i
                    break
                }
            }
            if (audioTrackIndex < 0) throw Exception("No audio track found")

            extractor.selectTrack(audioTrackIndex)
            val inputFormat = extractor.getTrackFormat(audioTrackIndex)
            val mime = inputFormat.getString(MediaFormat.KEY_MIME) ?: throw Exception("No MIME type")
            val inputSampleRate = inputFormat.getInteger(MediaFormat.KEY_SAMPLE_RATE)
            val inputChannels = inputFormat.getInteger(MediaFormat.KEY_CHANNEL_COUNT)

            val decoder = MediaCodec.createDecoderByType(mime)
            decoder.configure(inputFormat, null, null, 0)
            decoder.start()

            // Streams to disk: a long recording (50 min ≈ 96 MB of 16 kHz PCM) must
            // not be held in memory, or the whole app dies with OutOfMemoryError.
            val out = BufferedOutputStream(FileOutputStream(outputPath), 1 shl 16)
            out.write(ByteArray(WAV_HEADER_SIZE))
            val ratio = inputSampleRate.toDouble() / TARGET_RATE
            var outIndex = 0L
            var chunkStart = 0L
            val bufferInfo = MediaCodec.BufferInfo()
            var inputDone = false
            var outputDone = false

            while (!outputDone) {
                if (!inputDone) {
                    val inputBufferIndex = decoder.dequeueInputBuffer(10000)
                    if (inputBufferIndex >= 0) {
                        val inputBuffer = decoder.getInputBuffer(inputBufferIndex)!!
                        val sampleSize = extractor.readSampleData(inputBuffer, 0)
                        if (sampleSize < 0) {
                            decoder.queueInputBuffer(inputBufferIndex, 0, 0, 0,
                                MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                            inputDone = true
                        } else {
                            decoder.queueInputBuffer(inputBufferIndex, 0, sampleSize,
                                extractor.sampleTime, 0)
                            extractor.advance()
                        }
                    }
                }

                val outputBufferIndex = decoder.dequeueOutputBuffer(bufferInfo, 10000)
                if (outputBufferIndex >= 0) {
                    val outputBuffer = decoder.getOutputBuffer(outputBufferIndex)!!
                    val shortBuffer = outputBuffer.order(ByteOrder.LITTLE_ENDIAN).asShortBuffer()
                    val samples = ShortArray(shortBuffer.remaining())
                    shortBuffer.get(samples)

                    val mono = if (inputChannels > 1) {
                        ShortArray(samples.size / inputChannels) { frame ->
                            var sum = 0L
                            for (ch in 0 until inputChannels) sum += samples[frame * inputChannels + ch]
                            (sum / inputChannels).toInt().toShort()
                        }
                    } else {
                        samples
                    }

                    // Nearest-sample resampling, continuous across chunks.
                    val bytes = ByteBuffer.allocate(mono.size * 2).order(ByteOrder.LITTLE_ENDIAN)
                    while ((outIndex * ratio).toLong() < chunkStart + mono.size) {
                        bytes.putShort(mono[((outIndex * ratio).toLong() - chunkStart).toInt()])
                        outIndex++
                    }
                    out.write(bytes.array(), 0, bytes.position())
                    chunkStart += mono.size

                    decoder.releaseOutputBuffer(outputBufferIndex, false)
                    if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                        outputDone = true
                    }
                }
            }

            decoder.stop()
            decoder.release()
            extractor.release()
            out.close()

            patchWavHeader(outputPath, outIndex * 2)
        }

        private fun patchWavHeader(path: String, dataSize: Long) {
            val header = ByteBuffer.allocate(WAV_HEADER_SIZE).order(ByteOrder.LITTLE_ENDIAN)
            header.put("RIFF".toByteArray()).putInt((36 + dataSize).toInt())
            header.put("WAVE".toByteArray()).put("fmt ".toByteArray())
            header.putInt(16).putShort(1).putShort(1)
            header.putInt(TARGET_RATE).putInt(TARGET_RATE * 2).putShort(2).putShort(16)
            header.put("data".toByteArray()).putInt(dataSize.toInt())
            RandomAccessFile(path, "rw").use { it.write(header.array()) }
        }
    }
}
