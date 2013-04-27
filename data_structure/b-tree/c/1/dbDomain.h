#ifndef DBDOMAIN_H_INCLUDED
#define DBDOMAIN_H_INCLUDED

#include <sys/types.h>
#include "dbUtility.h"

result_t InitializeSearchTree(void);
/*
 * Usage: Read record from file (file in FILEPATH),and initial the blacklist datebase.
 * Inout:   @param  void
 * Output:  @return result_t
 *                  ------ R_SUCCESS, initial success
 *                  ------ R_FAILED,  initial failed
 */
result_t DestroySearchTree(void);
/*
 * Usage: Destroy the blacklist datebase, and free the resources(memory and locks).
 * Inout:   @param  void
 * Output:  @return result_t
 *                  ------ R_SUCCESS, free resource success
 *                  ------ R_FAILED,  free resource failed
 */
result_t SearchDomainName(char* domain, unsigned char* control_type,char** info);
/*
 * Usage: For search domain name in the blacklist datebase.
 * Input: @param  char* domain ----- domain name
 *        @param  unsigned char* control_type ----- store the return value (control type)
 *        @param  char** info ----- save the additional information of record (redirect IP)
 * Output: @return result_t
 *                ----- R_FOUND,found the name.
 *                ----- R_NOTFOUND, not found.
 */
int UpdateDomainName(void* collection,size_t size,unsigned char tag);
/*
 * Usage: For update data(add,delete or renew) to blacklist datebase.
 * Input: @param  void* collection ----- record set (exclude set-header)
 * 	  @param  size_t size  ----- data size of records (bytes)
 *        @param  unsigned char tag ----- operation type(normal or fast)
 * Output: @return int
 *                 ------ count of records which update success
 */
result_t AddListToBTree(void);
/*
 * Usage: flush Cache, and add records to BTee.
 * Inout:   @param  void
 * Output:  @return result_t
 *                  ------ R_SUCCESS, operste success
 *                  ------ R_FAILED,  operste failed
 */
result_t SaveToFile(void* collection,size_t size);
/*
 * Usage: Write the update data to file.
 * Input: @param  void* collection ----- record set (exclude set-header)
 * 	  @param  size_t size  ----- data size of records (bytes)
 * Output: @return result_t
 *                 ------ R_SUCCESS, save success
 *                 ------ R_FAILED, save failed
 */



#endif // DBDOMAIN_H_INCLUDED
