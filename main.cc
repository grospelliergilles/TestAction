#include <iostream>
#include <mpi.h>

int
main(int argc,char* argv[])
{
  std::cout << "Doing a commit\n";
  std::cout << "Doing a commit V3\n";
  std::cout << "Hello nb_argc=" << argc << "\n";

  MPI_Init(nullptr, nullptr);

  int world_size = 0;
  MPI_Comm_size(MPI_COMM_WORLD, &world_size);

  int world_rank = 0;
  MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);

  char processor_name[MPI_MAX_PROCESSOR_NAME];
  int name_len = 0;
  MPI_Get_processor_name(processor_name, &name_len);

  // Print off a hello world message
  printf("Hello world from processor %s, rank %d out of %d processors\n",
         processor_name, world_rank, world_size);

  // Finalize the MPI environment.
  MPI_Finalize();
}
