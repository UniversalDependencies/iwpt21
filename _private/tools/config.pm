#!/usr/bin/env perl
# Configuration of the CGI and other Perl scripts on the shared task submission site.
# Copyright © 2020-2021 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

package config;
use utf8;

BEGIN
{
    %config =
    (
        # Year of the IWPT shared task to be used in HTML headings etc.
        'year' => '2021',
        # Paths to important folders.
        'task_folder'            => '/home/zeman/iwpt2021',
        'system_unpacked_folder' => '/home/zeman/iwpt2021/_private/data/sysoutputs',
        # List of language codes and names.
        'languages' =>
        {
            'ar' => 'Arabic',
            'bg' => 'Bulgarian',
            'cs' => 'Czech',
            'nl' => 'Dutch',
            'en' => 'English',
            'et' => 'Estonian',
            'fi' => 'Finnish',
            'fr' => 'French',
            'it' => 'Italian',
            'lv' => 'Latvian',
            'lt' => 'Lithuanian',
            'pl' => 'Polish',
            'ru' => 'Russian',
            'sk' => 'Slovak',
            'sv' => 'Swedish',
            'ta' => 'Tamil',
            'uk' => 'Ukrainian'
        },
        # List and ordering of treebanks for each language.
        'dev_treebanks' =>
        {
            'ar' => ['Arabic-PADT'],
            'bg' => ['Bulgarian-BTB'],
            'cs' => ['Czech-FicTree', 'Czech-CAC', 'Czech-PDT'],
            'nl' => ['Dutch-Alpino', 'Dutch-LassySmall'],
            'en' => ['English-EWT', 'English-GUM'],
            'et' => ['Estonian-EDT'],
            'fi' => ['Finnish-TDT'],
            'fr' => ['French-Sequoia'],
            'it' => ['Italian-ISDT'],
            'lv' => ['Latvian-LVTB'],
            'lt' => ['Lithuanian-ALKSNIS'],
            'pl' => ['Polish-LFG', 'Polish-PDB'],
            'ru' => ['Russian-SynTagRus'],
            'sk' => ['Slovak-SNK'],
            'sv' => ['Swedish-Talbanken'],
            'ta' => ['Tamil-TTB'],
            'uk' => ['Ukrainian-IU']
        },
        'test_treebanks' =>
        {
            'ar' => ['Arabic-PADT'],
            'bg' => ['Bulgarian-BTB'],
            'cs' => ['Czech-FicTree', 'Czech-CAC', 'Czech-PDT', 'Czech-PUD'],
            'nl' => ['Dutch-Alpino', 'Dutch-LassySmall'],
            'en' => ['English-EWT', 'English-GUM', 'English-PUD'],
            'et' => ['Estonian-EDT', 'Estonian-EWT'],
            'fi' => ['Finnish-TDT', 'Finnish-PUD'],
            'fr' => ['French-Sequoia', 'French-FQB'],
            'it' => ['Italian-ISDT'],
            'lv' => ['Latvian-LVTB'],
            'lt' => ['Lithuanian-ALKSNIS'],
            'pl' => ['Polish-LFG', 'Polish-PDB', 'Polish-PUD'],
            'ru' => ['Russian-SynTagRus'],
            'sk' => ['Slovak-SNK'],
            'sv' => ['Swedish-Talbanken', 'Swedish-PUD'],
            'ta' => ['Tamil-TTB'],
            'uk' => ['Ukrainian-IU']
        },
        # Enhancement type selection for each treebank (only for information in the table).
        'enhancements' =>
        {
            'Arabic-PADT'        => 'no xsubj',
            'Bulgarian-BTB'      => 'no gapping',
            'Czech-FicTree'      => '', # all
            'Czech-CAC'          => '', # all
            'Czech-PDT'          => '', # all
            'Czech-PUD'          => 'no codepend',
            'Dutch-Alpino'       => '', # all
            'Dutch-LassySmall'   => '', # all
            'English-EWT'        => '', # all
            'English-GUM'        => '', # all
            'English-PUD'        => '', # all
            'Estonian-EDT'       => 'no xsubj',
            'Estonian-EWT'       => 'no codepend, no xsubj',
            'Finnish-TDT'        => '', # all
            'Finnish-PUD'        => 'no codepend, no xsubj',
            'French-Sequoia'     => 'no gapping, relcl, case',
            'French-FQB'         => 'no gapping, relcl, case',
            'Italian-ISDT'       => '', # all
            'Latvian-LVTB'       => '', # all
            'Lithuanian-ALKSNIS' => '', # all
            'Polish-LFG'         => 'no gapping', # no gapping
            'Polish-PDB'         => '', # all
            'Polish-PUD'         => '', # all
            'Russian-SynTagRus'  => 'no codepend', # no coord depend
            'Slovak-SNK'         => '', # all
            'Swedish-Talbanken'  => '', # all
            'Swedish-PUD'        => '', # all
            'Tamil-TTB'          => 'no gapping, xsubj',
            'Ukrainian-IU'       => '', # all
        }
    );
}

1;
