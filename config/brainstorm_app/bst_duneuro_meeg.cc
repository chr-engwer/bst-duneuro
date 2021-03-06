/*
This script is used to compute the leadfield matrix for EEG and/or MEG using duneuro toolbox

It uses as an argumenet the configuration file *.ini

The generated binary are integrated to Brainstorm software, for windows, mac and Linux.

Takfarinas MEDANI,
Juan GPC,

December 2019

*/
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <algorithm>
#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <numeric>

#include <dune/common/exceptions.hh>         // We use exceptions
#include <dune/common/parallel/mpihelper.hh> // An initializer of MPI
#include <dune/common/parametertree.hh>
#include <dune/common/parametertreeparser.hh>
#include <duneuro/common/matrix_utilities.hh>
#include <duneuro/io/dipole_reader.hh>
#include <duneuro/io/field_vector_reader.hh>
#include <duneuro/meeg/meeg_driver_factory.hh>
#include <duneuro/io/projections_reader.hh>

#include <brainstorm_app/bst_helper_fcns.h>

void runEEG(const Dune::ParameterTree &config)
{
    // set up driver
    auto driver = duneuro::MEEGDriverFactory<3>::make_meeg_driver(config);

    //read electrodes file
    auto electrodes =
        duneuro::FieldVectorReader<double, 3>::read(config.sub("electrodes"));
    driver->setElectrodes(electrodes, config.sub("electrodes"));

    // read dipoles file
    auto dipoles = duneuro::DipoleReader<double, 3>::read(config.sub("dipoles"));

    std::shared_ptr<duneuro::DenseMatrix<double>> transfer{nullptr};

    //check if transfer matrix file exists
    if (fileExists(config["brainstorm.output_folder"] + config["brainstorm.eeg_transfer_filename"]))
    {
        printf("\nThis is a known model. Load the transfer Matrix.\n");

        //read transfer file
        transfer = readTransferMatrix(config["brainstorm.output_folder"] + config["brainstorm.eeg_transfer_filename"]);
    }
    else
    {
        printf("\nThis is a new model. Compute the transfer Matrix.\n");
        // compute transfer matrix
        transfer = driver->computeEEGTransferMatrix(config.sub("solution"));

        //save transfer matrix to a file
        if (config["brainstorm.save_eeg_transfer_file"] == std::string("true"))
        {
            saveTransferMatrix(config["brainstorm.output_folder"] + config["brainstorm.eeg_transfer_filename"], transfer);
        }
    }

    // compute numerical solution transferred
    // auto solution = driver->makeDomainFunction();
    std::vector<std::vector<double>> num_transfer =
        driver->applyEEGTransfer(*transfer, dipoles, config.sub("solution"));
    //save files
    // std::cout << "outputfile = " << config["brainstorm.output_folder"] + config["brainstorm.eeg_leadfield_filename"] << std::endl;
    bool saveAsText{true};
    saveLFfile(config["brainstorm.output_folder"] + config["brainstorm.eeg_leadfield_filename"], 
                num_transfer, 
                dipoles.size(), 
                electrodes.size(),
                saveAsText);
}

void runMEG(const Dune::ParameterTree &config)
{
    // set up driver
    auto driver = duneuro::MEEGDriverFactory<3>::make_meeg_driver(config);
    auto coils = duneuro::FieldVectorReader<double, 3>::read(config.sub("coils"));
    auto projections =
        duneuro::ProjectionsReader<double, 3>::read(config.sub("projections")); //tak check this!!!
    driver->setCoilsAndProjections(coils, projections);

    // read dipoles
    auto dipoles = duneuro::DipoleReader<double, 3>::read(config.sub("dipoles"));

    std::shared_ptr<duneuro::DenseMatrix<double>> transfer{nullptr};

    //check if transfer matrix file exists
    if (fileExists(config["brainstorm.output_folder"] + config["brainstorm.meg_transfer_filename"]))
    {
        printf("\nThis is a known model. Load the transfer Matrix.\n");

        //read transfer file
        transfer = readTransferMatrix(config["brainstorm.output_folder"] + config["brainstorm.meg_transfer_filename"]);
    }
    else
    {
        printf("\nThis is a new model. Compute the transfer Matrix.\n");
        // compute transfer matrix
        transfer = driver->computeMEGTransferMatrix(config.sub("solution"));

        //save transfer matrix to a file
        if (config["brainstorm.save_meg_transfer_file"] == std::string("true"))
        {
            saveTransferMatrix(config["brainstorm.output_folder"] + config["brainstorm.meg_transfer_filename"], transfer);
        }
    }

    //auto solution = driver->makeDomainFunction();

    // compute numerical solution transferred
    auto num_transfer =
        driver->applyMEGTransfer(*transfer, dipoles, config.sub("solution"));

    //save files
    bool saveAsText{false};
    saveLFfile(config["brainstorm.output_folder"] + config["brainstorm.meg_leadfield_filename"], 
                num_transfer,
                dipoles.size(),
                coils.size(),
                saveAsText);
}

void runMEEG(const Dune::ParameterTree &config)
{
    // set up driver
    auto driver = duneuro::MEEGDriverFactory<3>::make_meeg_driver(config);

    //read electrodes file
    auto electrodes =
    duneuro::FieldVectorReader<double, 3>::read(config.sub("electrodes"));
    driver->setElectrodes(electrodes, config.sub("electrodes"));
    // read coils
    auto coils = duneuro::FieldVectorReader<double, 3>::read(config.sub("coils"));
    auto projections = duneuro::ProjectionsReader<double, 3>::read(config.sub("projections"));
    driver->setCoilsAndProjections(coils, projections);

    // read dipoles file
    auto dipoles = duneuro::DipoleReader<double, 3>::read(config.sub("dipoles"));


    std::shared_ptr<duneuro::DenseMatrix<double>> eeg_transfer{nullptr};

    //check if transfer matrix file exists
    if (fileExists(config["brainstorm.output_folder"] + config["brainstorm.eeg_transfer_filename"]))
    {
        printf("\nThis is a known EEG model. Load the EEG transfer Matrix.\n");

        //read transfer file
        eeg_transfer = readTransferMatrix(config["brainstorm.output_folder"] + config["brainstorm.eeg_transfer_filename"]);
    }
    else
    {
        printf("\nThis is a new EEG model. Compute the EEG transfer Matrix.\n");
        // compute transfer matrix
        eeg_transfer = driver->computeEEGTransferMatrix(config.sub("solution"));

        //save transfer matrix to a file
        if (config["brainstorm.save_eeg_transfer_file"] == std::string("true"))
        {
            saveTransferMatrix(config["brainstorm.output_folder"] + config["brainstorm.eeg_transfer_filename"], eeg_transfer);
        }
    }

    // compute numerical solution transferred
    //auto eeg_solution = driver->makeDomainFunction();
    std::vector<std::vector<double>> eeg_num_transfer =
        driver->applyEEGTransfer(*eeg_transfer, dipoles, config.sub("solution"));
    //save files
    bool saveAsText{false};
    saveLFfile(config["brainstorm.output_folder"] + config["brainstorm.eeg_leadfield_filename"],
                eeg_num_transfer,
                dipoles.size(),
                electrodes.size(),
                saveAsText);


    // Process fro MEG
    std::shared_ptr<duneuro::DenseMatrix<double>> meg_transfer{nullptr};

    //check if transfer matrix file exists
    if (fileExists(config["brainstorm.output_folder"] + config["brainstorm.meg_transfer_filename"]))
    {
        printf("\nThis is a known MEG model. Load the MEG transfer Matrix.\n");

        //read meg_transfer file
        meg_transfer = readTransferMatrix(config["brainstorm.output_folder"] + config["brainstorm.meg_transfer_filename"]);
    }
    else
    {
        printf("\nThis is a new MEG model. Compute the MEG transfer Matrix.\n");
        // compute transfer matrix
        meg_transfer = driver->computeMEGTransferMatrix(config.sub("solution"));

        //save transfer matrix to a file
        if (config["brainstorm.save_meg_transfer_file"] == std::string("true"))
        {
            saveTransferMatrix(config["brainstorm.output_folder"] + config["brainstorm.meg_transfer_filename"], meg_transfer);
        }
    }

    //auto meg_solution = driver->makeDomainFunction();

    // compute numerical solution transferred
    auto meg_num_transfer =
        driver->applyMEGTransfer(*meg_transfer, dipoles, config.sub("solution"));

    //save files
    saveLFfile(config["brainstorm.output_folder"] + config["brainstorm.meg_leadfield_filename"],
                meg_num_transfer,
                dipoles.size(),
                coils.size(),
                saveAsText);
}

int main(int argc, char **argv)
{
    try
    {
        //check for help arg inputs
        for (int i = 1; i < argc; ++i)
        {
            std::string inputParam{argv[i]};
            if (inputParam == std::string("--help") || inputParam == std::string("-h") || inputParam == std::string("--h") || inputParam == std::string("?"))
            {
                print_help_msg();
                return -1;
            }
        }

        if (argc != 2)
        {
            std::cerr << "\nPlease provide a config .ini file and the execution mode.\n";
            std::cerr << "The application needs two inputs. You can type --help for help.\n";
            print_help_msg();
            return -1;
        }

        Dune::MPIHelper::instance(argc, argv);
        Dune::ParameterTree config;                              
        Dune::ParameterTreeParser::readINITree(argv[1], config);

        std::string modality{config["brainstorm.modality"]};
        
        if (modality == std::string("eeg"))
        {
            runEEG(config);
        } 
        else if (modality == std::string("meg"))
        {
            runMEG(config);
        }
        else if (modality == std::string("meeg"))
        {
            runMEEG(config);
        }
        return 0;

    }
    catch (Dune::Exception &e)
    {
        std::cerr << "Dune reported error: " << e << std::endl;
        return -1;
    }
    catch (...)
    {
        std::cerr << "Unknown exception thrown!" << std::endl;
        return -1;
    }
}


