#include <sys/types.h>
#include <sys/stat.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <sys/sem.h>
#include <time.h>
#include <sys/time.h>
#include <stdio.h>
#include <string.h>
#include <pthread.h>
#include <errno.h>

#include "domainUpdate.h"
#include "dbDomain.h"

static char *share_region=NULL;
static int share_id=-1;
const int num_sems = 1; 	         /* number of semaphores in set */
static int sem_send, sem_recv;	         /* semaphore */
pthread_t update_thread;

#ifndef semun
union semun {
	int val;		        /* Value for SETVAL */
	struct semid_ds  *buf;	        /* Buffer for IPC_STAT, IPC_SET */
	unsigned short *array;	        /* Array for GETALL, SETALL */
	struct seminfo *__buf;	        /* Buffer for IPC_INFO (Linux specific) */
};
#endif

static void Logging(const char *filePath, const char *logString);
static void ProcessUpdate(void *buffer);
static int InitSem(void);	        /* initial semaphore */
static int semaphore_p(int sem_id);	/* P() */
static int semaphore_v(int sem_id);	/* V() */

static int semaphore_p(int sem_id)
{
	struct sembuf sem_b;

	sem_b.sem_num = 0;
	sem_b.sem_op = -1;	       /* P() */
	sem_b.sem_flg = SEM_UNDO;
	if (semop(sem_id, &sem_b, 1) == -1)
		return -1;
	return 0;
}

static int semaphore_v(int sem_id)
{
	struct sembuf sem_b;

	sem_b.sem_num = 0;
	sem_b.sem_op = +1;	      /* V() */
	sem_b.sem_flg = SEM_UNDO;
	if (semop(sem_id, &sem_b, 1) == -1)
		return -1;
	return 0;
}

static int InitSem(void)
{
	union semun sem_union;
	key_t sem_key1, sem_key2;
	char logString[256];

	sem_key1 = ftok(KEY_PATH, SEM_SEND_KEY);
	sem_key2 = ftok(KEY_PATH, SEM_RECV_KEY);
	if ((sem_key1 == -1)||(sem_key2 == -1))
	{
		memset(logString, 0, 256);
		snprintf(logString,256,"[ERROR] domainUpdate.c @ InitSem @ ftok --- %s", strerror(errno));
		goto err_out;
	}

	sem_send = semget(sem_key1, num_sems, IPC_CREAT|IPC_EXCL|0660);
	if(sem_send != -1)
	{
		sem_union.val = 1;
		if (semctl(sem_send, 0, SETVAL, sem_union) == -1)
		{
			memset(logString, 0, 256);
			snprintf(logString,256,"[ERROR] domainUpdate.c @ InitSem @ semctl --- %s", strerror(errno));
			goto err_out;
		}
	}else{
		sem_send = semget(sem_key1, num_sems, 0);
		if(sem_send == -1)
		{
			memset(logString, 0, 256);
			snprintf(logString,256,"[ERROR] domainUpdate.c @ InitSem @ semget --- %s", strerror(errno));
			goto err_out;
		}
	}
	sem_recv = semget(sem_key2, num_sems, IPC_CREAT|IPC_EXCL|0660);
	if (sem_recv != -1)
	{
		sem_union.val = 0;
		if (semctl(sem_recv, 0, SETVAL, sem_union) == -1)
		{
			memset(logString, 0, 256);
			snprintf(logString,256,"[ERROR] domainUpdate.c @ InitSem @ semctl --- %s", strerror(errno));
			goto err_out;
		}
	}else{
		sem_recv = semget(sem_key2, num_sems, 0);
		if(sem_send == -1)
		{
			memset(logString, 0, 256);
			snprintf(logString,256,"[ERROR] shareMem.c @ InitSem @ semget --- %s", strerror(errno));
			goto err_out;
		}
	}

	return 0;
err_out:
	Logging(PROG_ERROR_LOG, logString);
	return -1;
}

void* UpdateCreate(void *arg)
{
	//receive data from shared memory.
	char logString[256];
        int oldtype, ret, retry=0;
	pthread_setcanceltype(PTHREAD_CANCEL_ASYNCHRONOUS,&oldtype);

	while(1)
	{
		ret = semaphore_p(sem_recv);
		if(ret == -1)
		{
			memset(logString, 0, 256);
			if(retry < 3)
			{
				InitShm();	//尝试重新创建信号量及共享内存
				retry++;
				continue;
			}else{
				snprintf(logString,256,"[ERROR] domainUpdate.c @ UpdateCreate @ semaphore_p --- semaphore maybe destory, resume failed!");
				Logging(PROG_ERROR_LOG, logString);
				return (void*)(-1);
			}
		}
		retry = 0;

		ProcessUpdate(share_region);

		ret = semaphore_v(sem_send);
		if(ret == -1)
		{
			InitShm();	    // 尝试重新创建信号量及共享内存
			retry++;
		}
	}
	return arg;
}

static void ProcessUpdate(void *buffer)
{
	struct record_set_hdr *recdhdr;
	int sum=0;
        struct timeval t1,t2;
        struct timezone tz;
	unsigned long update_t, flush_t;
	char logString[256];

        recdhdr=(struct record_set_hdr *)buffer;

        if(recdhdr->data_type==DATA_TYPE_DOMAIN)
	{
		gettimeofday (&t1,&tz);
		sum=UpdateDomainName(buffer+sizeof(*recdhdr), recdhdr->recd_size,recdhdr->update_type);
		gettimeofday(&t2,&tz);
		update_t = (t2.tv_sec-t1.tv_sec)*1000000+(t2.tv_usec-t1.tv_usec);

		if(sum == 0)
		{
			snprintf(logString,256,"Type: DOMAIN.   <<FAILED>>   Update-Type: QUICK\n\
			    Time-Valid:  %lu us   Time-Total:  %lu us\n", update_t, update_t);
			goto out;
		}

       		 //write data to file;
        	SaveToFile(buffer+sizeof(*recdhdr),recdhdr->recd_size);

		if(recdhdr->update_type==UPDATE_QUICK)
		{
        	        gettimeofday (&t1,&tz);
			AddListToBTree();
			gettimeofday (&t2,&tz);
			flush_t = (t2.tv_sec-t1.tv_sec)*1000000+(t2.tv_usec-t1.tv_usec);
			memset(logString, 0, 256);
			snprintf(logString,256,"Type: DOMAIN.  Counts: %u.  Update-Type: QUICK\n\
			    Time-Valid:  %lu us   Time-Total:  %lu us\n", sum, update_t, update_t+flush_t);
			goto out;
		}else{
			memset(logString, 0, 256);
			snprintf(logString,256,"Type: DOMAIN.  Counts: %u.  Update-Type: NORMAL\n \
			    Time-Valid:  %lu us   Time-Total:  %lu us\n", sum, update_t, update_t);
			goto out;
		}
	}
out:
	Logging(PROG_UPDATE_LOG, logString);
}

result_t InitShm(void)
{
	key_t mem_key;
	char logString[256];

	mem_key = ftok(KEY_PATH, SHARE_MEM_KEY);
    if(mem_key==-1)
	{
		memset(logString, 0, 256);
		snprintf(logString,256,"[ERROR] domainUpdate.c @ InitShm @ ftok --- %s", strerror(errno));
		goto err_out;
	}
	share_id=shmget(mem_key,SHARE_SIZE,IPC_CREAT|0660);
        if(share_id==-1)
	{
		memset(logString, 0, 256);
		snprintf(logString,256,"[ERROR] domainUpdate.c @ InitShm @ shmget --- %s", strerror(errno));
		goto err_out;
	}
	if((share_region=shmat(share_id, 0, 0))==(void *)(-1))
	{
		memset(logString, 0, 256);
		snprintf(logString,256,"[ERROR] domainUpdate.c @ InitShm @ shmat --- %s", strerror(errno));
		goto err_out;
	}
	// 初始化信号量
	if(InitSem() == -1)
		return -1;

	return R_SUCCESS;
err_out:
	Logging(PROG_ERROR_LOG, logString);
	return R_FAILED;
}

result_t DetShm(void)
{
	// detach from share memory.
	if(share_region!=NULL)
		shmdt(share_region);
	return R_SUCCESS;
}

static void
Logging(const char *filePath, const char *logString )
{
	char timeLog[32];
	FILE *LogFile;
	time_t now = time(NULL);
	strftime(timeLog,sizeof(timeLog),"%d/%b/%Y:%H:%M:%S %Z",localtime(&now));

	if((LogFile = fopen(filePath,"a+")) == NULL) { perror("fopen");  return; }
	fprintf(LogFile,"[%s]  ",timeLog);
	fprintf(LogFile,"%s\n",logString);
	fclose(LogFile);
}
