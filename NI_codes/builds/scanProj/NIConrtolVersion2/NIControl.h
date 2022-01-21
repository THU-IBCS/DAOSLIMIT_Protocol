#include "extcode.h"
#ifdef __cplusplus
extern "C" {
#endif

/*!
 * Kx_4_ZScanning
 */
void __cdecl Kx_4_ZScanning(LVBoolean start, int32_t laser1, int32_t laser2, 
	int32_t laser3, int32_t laser4, int32_t k, double IfScanning, 
	double DCOffsetX, double DCOffsetY, double XShiftRatio, double YShiftRatio, 
	double VXPX, double VYPY, LStrHandle *VoltageScanningChannel, 
	LStrHandle *LaserTriggerChannel, double frequency, double z_num, 
	double delta_zX1um, int32_t Mode, double LoopDelaySecond, 
	double TriggerDelayMs, double RotationAlpha, double RotationBeta, 
	double ExposureTimeMs, double User1_float, int32_t User2_int);
/*!
 * SetStop
 */
void __cdecl SetStop(int32_t stop);

MgErr __cdecl LVDLLStatus(char *errStr, int errStrLen, void *module);

void __cdecl SetExecuteVIsInPrivateExecutionSystem(Bool32 value);

#ifdef __cplusplus
} // extern "C"
#endif

