/*
 * Copyright (c) 2010, University of Szeged
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Author: Miklos Maroti
 */

#include "TimerConfig.h"

generic configuration AlarmMicro32C()
{
	provides interface Alarm<TMicro, uint32_t>;
}

implementation
{
#if MCU_TIMER_MHZ_LOG2 == 0
	components new AlarmMcu32C();
	Alarm = AlarmMcu32C;
#else

#if MCU_TIMER_NO == 1
	components HplAtmRfa1Timer1C as HplAtmegaTimerC;
#elif MCU_TIMER_NO == 3
	components HplAtmRfa1Timer3C as HplAtmegaTimerC;
#endif

	components HplAtmegaCounterMicro32C, new AtmegaTransformCompareC(uint32_t, uint16_t, MCU_TIMER_MHZ_LOG2);
	AtmegaTransformCompareC.SubCompare -> HplAtmegaTimerC.Compare[unique(UQ_MCU_ALARM)];
	AtmegaTransformCompareC.HplAtmegaCounter -> HplAtmegaCounterMicro32C;
	
	components new AtmegaAlarmC(TMicro, uint32_t, 0, MCU_ALARM_MINDT);
	AtmegaAlarmC.HplAtmegaCounter -> HplAtmegaCounterMicro32C;
	AtmegaAlarmC.HplAtmegaCompare -> AtmegaTransformCompareC;
	
	Alarm = AtmegaAlarmC;
#endif
}
