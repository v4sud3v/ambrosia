package main

/*
#include <stdlib.h>
*/
import "C"

import (
	"encoding/json"
	"fmt"
	"unsafe"

	"github.com/v4sud3v/ambrosia/backend/engine"
)

type bridgeResponse struct {
	OK      bool    `json:"ok"`
	Message *string `json:"message,omitempty"`
	Bytes   *int64  `json:"bytes,omitempty"`
	Error   *string `json:"error,omitempty"`
}

func main() {}

//export AmbrosiaProcessAudioFile
func AmbrosiaProcessAudioFile(path *C.char) *C.char {
	if path == nil {
		return newBridgeCString(bridgeResponseWithError("AmbrosiaProcessAudioFile: path is nil"))
	}

	processor, err := engine.NewAudioProcessor(100 << 20)
	if err != nil {
		return newBridgeCString(bridgeResponseWithError(fmt.Sprintf("AmbrosiaProcessAudioFile: %v", err)))
	}

	result, err := processor.ProcessAudioFile(C.GoString(path))
	if err != nil {
		return newBridgeCString(bridgeResponseWithError(fmt.Sprintf("AmbrosiaProcessAudioFile: %v", err)))
	}
	if result == nil {
		return newBridgeCString(bridgeResponseWithError("AmbrosiaProcessAudioFile: result is nil"))
	}

	message := result.Message
	bytes := result.Bytes

	return newBridgeCString(bridgeResponse{
		OK:      true,
		Message: &message,
		Bytes:   &bytes,
	})
}

//export AmbrosiaFreeString
func AmbrosiaFreeString(value *C.char) {
	if value == nil {
		return
	}

	C.free(unsafe.Pointer(value))
}

func bridgeResponseWithError(message string) bridgeResponse {
	return bridgeResponse{
		OK:    false,
		Error: &message,
	}
}

func newBridgeCString(response bridgeResponse) *C.char {
	payload, err := json.Marshal(response)
	if err != nil {
		errorMessage := fmt.Sprintf("newBridgeCString: marshal response: %v", err)
		fallback := fmt.Sprintf(`{"ok":false,"error":%q}`, errorMessage)
		return C.CString(fallback)
	}

	return C.CString(string(payload))
}
