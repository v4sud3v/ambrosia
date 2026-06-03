package engine

import (
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
)

type AudioProcessor struct {
	MaxAudioBytes int64
}

type AudioResult struct {
	Message string `json:"message"`
	Bytes   int64  `json:"bytes"`
}

func NewAudioProcessor(maxAudioBytes int64) (*AudioProcessor, error) {
	if maxAudioBytes <= 0 {
		return nil, fmt.Errorf("NewAudioProcessor: max audio bytes must be positive")
	}

	return &AudioProcessor{
		MaxAudioBytes: maxAudioBytes,
	}, nil
}

func (processor *AudioProcessor) ProcessAudioFile(path string) (result *AudioResult, err error) {
	if processor == nil {
		return nil, fmt.Errorf("ProcessAudioFile: audio processor is nil")
	}
	if processor.MaxAudioBytes <= 0 {
		return nil, fmt.Errorf("ProcessAudioFile: max audio bytes must be positive")
	}

	cleanPath := filepath.Clean(strings.TrimSpace(path))
	if cleanPath == "." {
		return nil, fmt.Errorf("ProcessAudioFile: path is required")
	}

	fileInfo, statErr := os.Stat(cleanPath)
	if statErr != nil {
		return nil, fmt.Errorf("ProcessAudioFile: stat audio file: %w", statErr)
	}
	if !fileInfo.Mode().IsRegular() {
		return nil, fmt.Errorf("ProcessAudioFile: audio path is not a regular file")
	}

	defer func() {
		removeErr := os.Remove(cleanPath)
		if removeErr == nil || errors.Is(removeErr, os.ErrNotExist) {
			return
		}
		if err != nil {
			err = fmt.Errorf("ProcessAudioFile: cleanup audio file: %w; previous error: %v", removeErr, err)
			return
		}
		err = fmt.Errorf("ProcessAudioFile: cleanup audio file: %w", removeErr)
	}()

	// Assumption: until the local model decoder is wired in, malformed input means
	// a file that is not one of the supported audio container extensions.
	if !isSupportedAudioPath(cleanPath) {
		return nil, fmt.Errorf("ProcessAudioFile: unsupported audio file type")
	}

	file, openErr := os.Open(cleanPath)
	if openErr != nil {
		return nil, fmt.Errorf("ProcessAudioFile: open audio file: %w", openErr)
	}
	defer func() {
		closeErr := file.Close()
		if closeErr == nil {
			return
		}
		if err != nil {
			err = fmt.Errorf("ProcessAudioFile: close audio file: %w; previous error: %v", closeErr, err)
			return
		}
		err = fmt.Errorf("ProcessAudioFile: close audio file: %w", closeErr)
	}()

	bytesRead, copyErr := io.Copy(io.Discard, io.LimitReader(file, processor.MaxAudioBytes+1))
	if copyErr != nil {
		return nil, fmt.Errorf("ProcessAudioFile: read audio file: %w", copyErr)
	}
	if bytesRead == 0 {
		return nil, fmt.Errorf("ProcessAudioFile: audio file is empty")
	}
	if bytesRead > processor.MaxAudioBytes {
		return nil, fmt.Errorf("ProcessAudioFile: audio file exceeds maximum size")
	}

	return &AudioResult{
		Message: "audio processed locally",
		Bytes:   bytesRead,
	}, nil
}

func isSupportedAudioPath(path string) bool {
	extension := strings.ToLower(filepath.Ext(path))

	switch extension {
	case ".aac", ".flac", ".m4a", ".mp3", ".ogg", ".opus", ".wav", ".webm":
		return true
	default:
		return false
	}
}
