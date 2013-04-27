#ifndef DOMAINUPDATE_H_INCLUDED
#define DOMAINUPDATE_H_INCLUDED

#include <pthread.h>
#include "dbUtility.h"

extern pthread_t update_thread;

result_t InitShm(void);
/*
 * Usage: initial Share memory, attach to share memory.
 * @param   void  --- null
 * @return  result_t
             ---- R_SUCCESS: initial success;
             ---- R_FAILED: initial failed
 */
result_t DetShm(void);
/*
 * Usage: detach from share memory
 * @param   void  --- null
 * @return  result_t
             ---- R_SUCCESS: operate success;
             ---- R_FAILED: operate failed
 */

void* UpdateCreate(void *arg);
/*
 * Usage: process update of url (used for thread)
 * @param   void *arg --- nothing
 * @return  void* --- nothing
 */

#endif // DOMAINUPDATE_H_INCLUDED
