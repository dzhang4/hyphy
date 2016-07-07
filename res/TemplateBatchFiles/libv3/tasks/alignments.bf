LoadFunctionLibrary("../IOFunctions.bf");
LoadFunctionLibrary("../terms-json.bf");


/**
 * Get metadata from existing dataset
 * @name alignments.ReadCodonDataSet
 * @param dataset_name - id of dataset
 * @returns {Dictionary} r - metadata pertaining to the dataset
 */
lfunction alignments.ReadCodonDataSet(dataset_name) {
    return alignments.ReadCodonDataSetFromPath(dataset_name, None);
}

/**
 * Reads dataset from a file path
 * @name alignments.ReadCodonDataSetFromPath
 * @param {String} dataset_name - name of variable you would like to set the dataset to
 * @param {String} path - path to alignment file
 * @returns {Dictionary} r - metadata pertaining to the dataset
 */
lfunction alignments.ReadCodonDataSetFromPath(dataset_name, path) {
    ExecuteAFile(HYPHY_LIB_DIRECTORY + "TemplateBatchFiles" + DIRECTORY_SEPARATOR + "TemplateModels" + DIRECTORY_SEPARATOR + "chooseGeneticCode.def");

    if (Type(path) == "String") {
        DataSet ^ dataset_name = ReadDataFile(path);
    } else {
        DataSet ^ dataset_name = ReadDataFile(PROMPT_FOR_FILE);
        path = ^ "LAST_FILE_PATH";
    }

    r = alignments.ReadNucleotideDataSet_aux(dataset_name);

    r * {
        "code": _Genetic_Code,
        "stop": GeneticCodeExclusions,
        "file": path,
        "sequences": Eval( ^ "`dataset_name`.species")
    };


    return r;
}

/**
 * Helper function to readCodonDataSetFromPath; do not use
 * @name alignments.ReadNucleotideDataSet_aux
 * @private
 * @param dataset_name
 * @returns {Dictionary} r - metadata pertaining to the dataset
 */
lfunction alignments.ReadNucleotideDataSet_aux(dataset_name) {

    partitions = None;
    dfpm = utility.GetEnvVariable("DATA_FILE_PARTITION_MATRIX");

    partitions = {
        {
            "default",
            ""
        }
    };


    if (Type(dfpm) == "Matrix") {
        if (Rows(dfpm) > 0) {
            partitions = Transpose(dfpm);
        }
    }

    return {
        "sequences": Eval("`dataset_name`.species"),
        "sites": Eval("`dataset_name`.sites"),
        "name-mapping": Eval("`dataset_name`.mapping"),
        "partitions": partitions
    };
}

/**
 * Get sequence names from existing dataset
 * @name alignments.GetSequenceNames
 * @param {String} dataset_name - name of dataset to get sequence names from
 * @returns {Dictionary} list of sequence names
 */
lfunction alignments.GetSequenceNames(dataset_name) {
    GetString(result, ^ dataset_name, -1);
    return result;
}

/**
 * Read Nucleotide dataset from file_name
 * @name alignments.ReadNucleotideDataSet
 * @param dataset_name - the name of the dataset you wish to use
 * @param file_name - path to file
 * @returns {Dictionary} r - metadata pertaining to the dataset
 */
lfunction alignments.ReadNucleotideDataSet(dataset_name, file_name) {
    if (Type(file_name) == "String") {
        //
        DataSet ^ dataset_name = ReadDataFile( ^ file_name);
    } else {
        DataSet ^ dataset_name = ReadDataFile(PROMPT_FOR_FILE);
        file_name = LAST_FILE_PATH;
    }

    result = alignments.ReadNucleotideDataSet_aux(dataset_name);
    result["file"] = file_name;
    return result;
}

/**
 * Read dataset from data
 * @name alignments.ReadNucleotideDataSetString
 * @param {String} dataset_name - the name of the dataset you wish to use
 * @param {String} data - the data you wish to parse
 * @returns {Dictionary} r - metadata pertaining to the dataset
 */
function alignments.ReadNucleotideDataSetString(dataset_name, data) {
    ExecuteCommands("DataSet `dataset_name` = ReadFromString (data);");
    return alignments.ReadNucleotideDataSet_aux(dataset_name);
}

/**
 * Prompts user for genetic code and alignment
 * @name alignments.PromptForGeneticCodeAndAlignment
 * @param {String} dataset_name - the name  of the dataset you wish to use
 * @param {String} datafilter_name - the name  of the dataset filter you wish to use
 * @returns {Dictionary} r - metadata pertaining to the dataset
 */
function alignments.PromptForGeneticCodeAndAlignment(dataset_name, datafilter_name) {
    return alignments.LoadCodonDataFile(dataset_name, datafilter_name, alignments.ReadCodonDataSet(dataset_name));
}

/**
 * Loads genetic code and alignment from file path
 * @name alignments.LoadGeneticCodeAndAlignment
 * @param {String} dataset_name - the name  of the dataset you wish to use
 * @param {String} datafilter_name - the name  of the dataset filter you wish to use
 * @param {String} path - path to file
 * @returns {Dictionary} r - metadata pertaining to the dataset
 */
function alignments.LoadGeneticCodeAndAlignment(dataset_name, datafilter_name, path) {
    return alignments.LoadCodonDataFile(dataset_name, datafilter_name, alignments.ReadCodonDataSetFromPath(dataset_name, path));
}

/**
 * Creates codon dataset filter from data set
 * @name alignments.LoadCodonDataFile
 * @param {String} datafilter_name - the name  of the dataset filter you wish to use
 * @param {String} dataset_name - the name of the existing dataset
 * @param {Dictionary} data_info - DataSet metadata information
 * @returns {Dictionary} updated data_info that includes the number of sites, dataset, and datafilter name
 */
function alignments.LoadCodonDataFile(dataset_name, datafilter_name, data_info) {
    DataSetFilter ^ datafilter_name = CreateFilter( ^ dataset_name, 3, , , data_info["stop"]);
    io.CheckAssertion("`datafilter_name`.sites*3==`dataset_name`.sites", "The input alignment must not contain stop codons");
    data_info["sites"] = ^ "`datafilter_name`.sites";
    data_info["dataset"] = dataset_name;
    data_info["datafilter"] = datafilter_name;
    return data_info;
}

/**
 * Creates nucleotide dataset filter from file
 * @name alignments.ReadNucleotideAlignment
 * @param {String} file_name - The location of the alignment file
 * @param {String} datafilter_name - the name  of the dataset filter you wish to use
 * @param {String} dataset_name - the name of the dataset you wish to use
 * @returns {Dictionary} updated data_info that includes the number of sites, dataset, and datafilter name
 */
function alignments.ReadNucleotideAlignment(file_name, dataset_name, datafilter_name) {
    data_info = alignments.ReadNucleotideDataSet(dataset_name, file_name);
    ExecuteCommands("DataSetFilter `datafilter_name` = CreateFilter (`dataset_name`,1)");
    data_info["sites"] = Eval("`datafilter_name`.sites");
    data_info["dataset"] = dataset_name;
    data_info["datafilter"] = datafilter_name;

    return data_info;
}

/**
 * Defines filters for multiple partitions
 * @name alignments.DefineFiltersForPartitions
 * @param {Matrix} partitions - a row vector of dictionaries with partition information containing "name" and "filter-string" attributes
 * @param {DataSet} source_data - the existing dataset to partition
 * @returns {Matrix} filters - a list of newly created dataset filters
 */
lfunction alignments.DefineFiltersForPartitions(partitions, source_data, prefix, data_info) {
    part_count = utility.Array1D(partitions);
    filters = {};
    if (utility.CheckKey(data_info, "code", "Matrix")) {
        for (i = 0; i < part_count; i += 1) {
            this_filter = {};
            DataSetFilter test = CreateFilter( ^ source_data, 1, (partitions[i])["filter-string"]);
            this_filter["name"] = prefix + (partitions[i])["name"];
            DataSetFilter ^ (this_filter["name"]) = CreateFilter( ^ source_data, 3, (partitions[i])["filter-string"], , data_info["stop"]);
            diff = test.sites - 3 * ^ (this_filter["name"] + ".sites");
            io.CheckAssertion("`&diff` == 0", "Partition " + (filters["names"])[i] + " is either has stop codons or is not in frame");
            this_filter["coverage"] = utility.DictToArray(utility.Map(utility.Filter( ^ (this_filter["name"] + ".site_map"), "_value_", "_value_%3==0"), "_value_", "_value_$3"));

            filters + this_filter;
        }

    } else {
        for (i = 0; i < part_count; i += 1) {
            this_filter = {};
            this_filter["name"] = prefix + (partitions[i])["name"];
            DataSetFilter ^ (this_filter["name"]) = CreateFilter( ^ source_data, 1, (partitions[i])["filter-string"]);
            this_filter["coverage"] = ^ (this_filter["name"] + ".site_map");
            filters + this_filter;

        }

    }
    return filters;
}

/**
 * @name alignments.serialize_site_filter
 * @param {DataFilter} data_filter
 * @param {Number} site_index
 * @returns {String} a string representation of data_filter
 */
lfunction alignments.serialize_site_filter (data_filter, site_index) {
    GetDataInfo (fi, ^data_filter, "PARAMETERS");
    utility.ToggleEnvVariable ("DATA_FILE_PRINT_FORMAT", 9);
    utility.ToggleEnvVariable ("IS_TREE_PRESENT_IN_DATA", FALSE);
    DataSetFilter temp = CreateFilter (^data_filter,fi["ATOM_SIZE"],'' + site_index*fi["ATOM_SIZE"] + '-' + ((site_index+1)*fi["ATOM_SIZE"]-1),'',fi["EXCLUSIONS"]);
    Export (filter_string, temp);
    utility.ToggleEnvVariable ("DATA_FILE_PRINT_FORMAT", None);
    utility.ToggleEnvVariable ("IS_TREE_PRESENT_IN_DATA", None);
    return '
        lfunction __make_filter (name) {
            DataSet hidden = ReadFromString ("`filter_string`");
            DataSetFilter ^name = CreateFilter (hidden, `""+fi['ATOM_SIZE']`,,,"`fi['EXCLUSIONS']`");
        };
    ';
}

/**
 * @name alignments.Extract_site_patterns
 * @param {DataFilter} data_filter
 * @returns for a data filter, returns a dictionary like this
 *
 *    "pattern id":
 *        "sites" : sites (0-based) mapping to this pattern
 *        "is_constant" : T/F (is the site constant w/matching ambigs)
 *
 *        "0":{
 *           "sites":{
 *             "0":0
 *            },
 *           "is_constant":0
 *          },
 *
 *         "1":{
 *           "sites":{
 *             "0":1
 *            },
 *           "is_constant":1
 *          },
 *...
 *         "34":{
 *           "sites":{
 *             "0":34,
 *             "1":113
 *            },
 *           "is_constant":1
 *          },
 *        ...
 */
lfunction alignments.Extract_site_patterns (data_filter) {
    utility.ToggleEnvVariable ("COUNT_GAPS_IN_FREQUENCIES", FALSE);

    site_info = {};
    GetDataInfo (pattern_list, ^data_filter);
    site_characters = {};
    sequence_count = ^(data_filter + ".species");

    utility.ForEachPair (pattern_list, "_site_index_", "_pattern_",
        '
        utility.EnsureKey (`&site_info`, _pattern_);
        utility.EnsureKey (`&site_info`[_pattern_], "sites");

        (`&site_info`[_pattern_])["sites"] + _site_index_[1];

        if (Abs ((`&site_info`[_pattern_])["sites"]) == 1) {
            // first time we see this site
            GetDataInfo (`&site_characters`, `data_filter`, -1, _pattern_);
            `&site_characters` = utility.Filter (`&site_characters`,
                                                 "_value_",
                                                 "(+_value_>0)");

            (`&site_info`[_pattern_])["is_constant"] = Abs (`&site_characters`) <= 1;

        }
        '
    );

    utility.ToggleEnvVariable ("COUNT_GAPS_IN_FREQUENCIES", None);

    return site_info;

}
