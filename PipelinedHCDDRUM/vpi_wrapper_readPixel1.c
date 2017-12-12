/*
 * Generated by Bluespec Compiler, version 2016.07.beta1 (build 34806, 2016-07-05)
 * 
 * On Wed Dec  6 15:36:18 GMT 2017
 * 
 * To automatically register this VPI wrapper with a Verilog simulator use:
 *     #include "vpi_wrapper_readPixel1.h"
 *     void (*vlog_startup_routines[])() = { readPixel1_vpi_register, 0u };
 * 
 * For a Verilog simulator which requires a .tab file, use the following entry:
 * $imported_readPixel1 call=readPixel1_calltf size=32 acc=rw:%TASK
 * 
 * For a Verilog simulator which requires a .sft file, use the following entry:
 * $imported_readPixel1 vpiSysFuncSized 32 unsigned
 */
#include <stdlib.h>
#include <vpi_user.h>
#include "bdpi.h"

/* the type of the wrapped function */
unsigned int readPixel1(unsigned int , unsigned int , unsigned int );

/* VPI wrapper function */
PLI_INT32 readPixel1_calltf(PLI_BYTE8 *user_data)
{
  vpiHandle hCall;
  unsigned int arg_1;
  unsigned int arg_2;
  unsigned int arg_3;
  unsigned int vpi_result;
  vpiHandle *handle_array;
  
  /* retrieve handle array */
  hCall = vpi_handle(vpiSysTfCall, 0);
  handle_array = vpi_get_userdata(hCall);
  if (handle_array == NULL)
  {
    vpiHandle hArgList;
    hArgList = vpi_iterate(vpiArgument, hCall);
    handle_array = malloc(sizeof(vpiHandle) * 4u);
    handle_array[0u] = hCall;
    handle_array[1u] = vpi_scan(hArgList);
    handle_array[2u] = vpi_scan(hArgList);
    handle_array[3u] = vpi_scan(hArgList);
    vpi_put_userdata(hCall, handle_array);
    vpi_free_object(hArgList);
  }
  
  /* create return value */
  make_vpi_result(handle_array[0u], &vpi_result, DIRECT);
  
  /* copy in argument values */
  get_vpi_arg(handle_array[1u], &arg_1, DIRECT);
  get_vpi_arg(handle_array[2u], &arg_2, DIRECT);
  get_vpi_arg(handle_array[3u], &arg_3, DIRECT);
  
  /* call the imported C function */
  vpi_result = readPixel1(arg_1, arg_2, arg_3);
  
  /* copy out return value */
  put_vpi_result(handle_array[0u], &vpi_result, DIRECT);
  
  /* free argument storage */
  free_vpi_args();
  vpi_free_object(hCall);
  
  return 0;
}

/* sft: $imported_readPixel1 vpiSysFuncSized 32 unsigned */

/* tab: $imported_readPixel1 call=readPixel1_calltf size=32 acc=rw:%TASK */

PLI_INT32 readPixel1_sizetf(PLI_BYTE8 *user_data)
{
  return 32u;
}

/* VPI wrapper registration function */
void readPixel1_vpi_register()
{
  s_vpi_systf_data tf_data;
  
  /* Fill in registration data */
  tf_data.type = vpiSysFunc;
  tf_data.sysfunctype = vpiSizedFunc;
  tf_data.tfname = "$imported_readPixel1";
  tf_data.calltf = readPixel1_calltf;
  tf_data.compiletf = 0u;
  tf_data.sizetf = readPixel1_sizetf;
  tf_data.user_data = "$imported_readPixel1";
  
  /* Register the function with VPI */
  vpi_register_systf(&tf_data);
}
