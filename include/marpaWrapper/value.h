#ifndef MARPAWRAPPER_VALUE_H
#define MARPAWRAPPER_VALUE_H

#include "genericStack.h"
#include "genericLogger.h"
#include "marpaWrapper/recognizer.h"
#include "marpaWrapper/export.h"

/***********************/
/* Opaque object types */
/***********************/
typedef struct marpaWrapperValue marpaWrapperValue_t;

/* Callbacks */
/* --------- */
typedef short (*marpaWrapperValueRuleCallback_t)(void *userDatavp, int rulei, int arg0i, int argni, int resulti);
typedef short (*marpaWrapperValueSymbolCallback_t)(void *userDatavp, int symboli, int argi, int resulti);
typedef short (*marpaWrapperValueNullingCallback_t)(void *userDatavp, int symboli, int resulti);
typedef short (*marpaWrapperValueCallback_t)(void *userDatavp);


/* --------------- */
/* General options */
/* --------------- */
typedef struct marpaWrapperValueOption {
  genericLogger_t                   *genericLoggerp;             /* Default: NULL */
  short                              highRankOnlyb;              /* Default: 1 */
  short                              orderByRankb;               /* Default: 1 */
  short                              ambiguousb;                 /* Default: 0 */
  short                              nullb;                      /* Default: 0 */
} marpaWrapperValueOption_t;

#ifdef __cplusplus
extern "C" {
#endif
  marpaWrapper_EXPORT marpaWrapperValue_t *marpaWrapperValue_newp(marpaWrapperRecognizer_t *marpaWrapperRecognizerp, marpaWrapperValueOption_t *marpaWrapperValueOptionp);
  marpaWrapper_EXPORT short                marpaWrapperValue_valueb(marpaWrapperValue_t               *marpaWrapperValuep,
								    void                              *userDatavp,
								    marpaWrapperValueRuleCallback_t    ruleCallbackp,
								    marpaWrapperValueSymbolCallback_t  symbolCallbackp,
								    marpaWrapperValueNullingCallback_t nullingCallbackp);
  marpaWrapper_EXPORT void                 marpaWrapperValue_freev(marpaWrapperValue_t *marpaWrapperValuep);
#ifdef __cplusplus
}
#endif

#endif /* MARPAWRAPPER_VALUE_H */