package engine

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestProcessAudioFileHappyPath(t *testing.T) {
	path := writeTempAudioFile(t, "recording.m4a", []byte{1, 2, 3, 4})
	processor := newTestAudioProcessor(t, 100)

	result, err := processor.ProcessAudioFile(path)
	if err != nil {
		t.Fatalf("ProcessAudioFile returned error: %v", err)
	}
	if result == nil {
		t.Fatal("ProcessAudioFile returned nil result")
	}
	if result.Bytes != 4 {
		t.Fatalf("expected 4 bytes, got %d", result.Bytes)
	}
	if result.Message == "" {
		t.Fatal("expected message")
	}
	assertRemoved(t, path)
}

func TestProcessAudioFileRejectsEmptyInput(t *testing.T) {
	path := writeTempAudioFile(t, "empty.wav", []byte{})
	processor := newTestAudioProcessor(t, 100)

	result, err := processor.ProcessAudioFile(path)
	if err == nil {
		t.Fatal("expected error")
	}
	if result != nil {
		t.Fatalf("expected nil result, got %#v", result)
	}
	if !strings.Contains(err.Error(), "audio file is empty") {
		t.Fatalf("expected empty input error, got %v", err)
	}
	assertRemoved(t, path)
}

func TestProcessAudioFileRejectsMalformedInput(t *testing.T) {
	path := writeTempAudioFile(t, "recording.txt", []byte("not audio"))
	processor := newTestAudioProcessor(t, 100)

	result, err := processor.ProcessAudioFile(path)
	if err == nil {
		t.Fatal("expected error")
	}
	if result != nil {
		t.Fatalf("expected nil result, got %#v", result)
	}
	if !strings.Contains(err.Error(), "unsupported audio file type") {
		t.Fatalf("expected unsupported type error, got %v", err)
	}
	assertRemoved(t, path)
}

func TestProcessAudioFileReturnsErrorForMissingFile(t *testing.T) {
	path := filepath.Join(t.TempDir(), "missing.m4a")
	processor := newTestAudioProcessor(t, 100)

	result, err := processor.ProcessAudioFile(path)
	if err == nil {
		t.Fatal("expected error")
	}
	if result != nil {
		t.Fatalf("expected nil result, got %#v", result)
	}
	if !strings.Contains(err.Error(), "stat audio file") {
		t.Fatalf("expected stat error, got %v", err)
	}
}

func TestProcessAudioFileRejectsDirectoryPath(t *testing.T) {
	path := t.TempDir()
	processor := newTestAudioProcessor(t, 100)

	result, err := processor.ProcessAudioFile(path)
	if err == nil {
		t.Fatal("expected error")
	}
	if result != nil {
		t.Fatalf("expected nil result, got %#v", result)
	}
	if !strings.Contains(err.Error(), "not a regular file") {
		t.Fatalf("expected regular file error, got %v", err)
	}
}

func TestProcessAudioFileRejectsOversizedInput(t *testing.T) {
	path := writeTempAudioFile(t, "recording.m4a", []byte{1, 2, 3, 4})
	processor := newTestAudioProcessor(t, 3)

	result, err := processor.ProcessAudioFile(path)
	if err == nil {
		t.Fatal("expected error")
	}
	if result != nil {
		t.Fatalf("expected nil result, got %#v", result)
	}
	if !strings.Contains(err.Error(), "exceeds maximum size") {
		t.Fatalf("expected maximum size error, got %v", err)
	}
	assertRemoved(t, path)
}

func TestNewAudioProcessorRejectsInvalidLimit(t *testing.T) {
	processor, err := NewAudioProcessor(0)
	if err == nil {
		t.Fatal("expected error")
	}
	if processor != nil {
		t.Fatalf("expected nil processor, got %#v", processor)
	}
}

func newTestAudioProcessor(t *testing.T, maxAudioBytes int64) *AudioProcessor {
	t.Helper()

	processor, err := NewAudioProcessor(maxAudioBytes)
	if err != nil {
		t.Fatalf("NewAudioProcessor returned error: %v", err)
	}

	return processor
}

func writeTempAudioFile(t *testing.T, name string, content []byte) string {
	t.Helper()

	path := filepath.Join(t.TempDir(), name)
	if err := os.WriteFile(path, content, 0o600); err != nil {
		t.Fatalf("write temp audio file: %v", err)
	}

	return path
}

func assertRemoved(t *testing.T, path string) {
	t.Helper()

	_, err := os.Stat(path)
	if err == nil {
		t.Fatalf("expected %s to be removed", path)
	}
	if !os.IsNotExist(err) {
		t.Fatalf("stat removed file: %v", err)
	}
}
