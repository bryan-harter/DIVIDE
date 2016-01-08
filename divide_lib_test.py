#
#  Place whatever relevant header info is needed here
#  Including import statements
#
# Author: McGouldrick
#
# Version 0.1 (2015-Nov-30)
#
# This will be a library of the DIVIDE IDL toolkit translated into python
#
#-------------------------------------------------------------------
#
import numpy as np
import sys

def param_list( insitu ):
    '''
    Return a listing of all parameters present in the given 
    insitu data dictionary/structure.  At present, this does
    not include the fancy formatting that can more easily 
    distinguish one instrument form another.
    '''
    index = 1
    ParamList = []
    for base_tag in insitu.dtype.names:
        try:
            first_level_tags = insitu[base_tag][0].dtype.names
            for first_level_tag in first_level_tags:
                ParamList.append("#%3d %s.%s" % 
                                 (index,base_tag,first_level_tag) )
                index = index + 1
        except:
            pass
    return ParamList

#---------------------------------------------------------------------
def param_range( kp, iuvs=None ):
    '''
    Print the range of times and orbits for the provided insitu data.
    If iuvs data are also provided, return orbit numbers for IUVS data.
    At present, not configured to handle IUVS data.
    '''
#
# First, the case where insitu data are provided
#
    if kp.dtype.names[0] == 'TIME_STRING':
        print "The loaded insitu KP data set contains data between"
        print( "   %s and %s" % (kp[0].time_string, kp[-1].time_string) )
        print "Equivalently, this corresponds to orbits"
        print ( "   %6d and %6d." % (kp[0].orbit, kp[-1].orbit) )
#
#  Next, the case where IUVS data are provided
#
    iuvs_data = False
    iuvs_tags = ['CORONA_LO_HIGH','CORONA_LO_LIMB','CORONA_LO_DISK',
                 'CORONA_E_HIGH','CORONA_E_LIMB','CORONA_E_DISK',
                 'APOAPSE','PERIAPSE','STELLAR_OCC']
    if kp.dtype.names[0] in iuvs_tags:
        print "The loaded IUVS KP data set contains data between orbits"
        print "   %6d and %6d." % (kp[0].orbit, kp[-1].orbit)
#
#  Finally, the case where both insitu and IUVS are provided
#
    if iuvs is not None: 
        print "The loaded IUVS KP data set contains data between orbits"
        print "   %6d and %6d." % (iuvs[0].orbit, iuvs[-1].orbit)
        insitu_min, insitu_max = np.nanmin(kp.orbit), np.nanmax(kp.orbit)
        if ( np.nanmax(iuvs.orbit) < insitu_min or 
             np.nanmin(iuvs.orbit) > insitu_max ): 
            print "*** WARNING ***"
            print "There is NO overlap between the supplied insitu and IUVS"
            print "  data structures.  We cannot guarantee your safety "
            print "  should you attempt to display these IUVS data against"
            print "  these insitu-supplied emphemeris data."
    return # No information to return

#--------------------------------------------------------------------------

def range_select( kp, time ):
    '''
    Given an insitu KP data set and time information in the form of 
    either an array of times or orbits, return the starting and ending
    indices of the provided dataset for the requested range.
    '''
    import bisect # can I import htis here only?
    from datetime import datetime
    # First, define the time strings if needed
    dt = [datetime.strptime(i, '%Y-%m-%dT%H:%M:%S') for i in kp.time_string]
    # Now check the input time values
    try:
        orbit = int(time) # time given as single integer orbit number
        mask = np.where( orbit == kp.orbit )
        return kp[mask]
    except:
        if np.count_nonzero(time) == 1:
            # time given as single date-time string
            # First convert it to a date-time object
            dt_in = datetime.strptime(time, '%Y-%m-%dT%H:%M:%S')
            # select 24 hours of data following given time
            # for debugging purposes, use 3 hr
            dt_delta = [(i-dt_in).total_seconds() for i in dt]
            mask = np.all([np.array(dt_delta) < 10800., 
                              np.array(dt_delta) > 0], axis=0 )
            return kp[mask]
        else:
            # Either we have two ints or two strings
            try: 
                # If successful, we have two ints
                int(time[0])
                orbit = np.array(time)
                mask = np.all([np.min(orbit) <= kp.orbit, 
                                  np.max(orbit) >= kp.orbit], axis=0 )
                return kp[mask]
            except:
                # Check for data times between given times
                dt_in = [datetime.strptime(i, '%Y-%m-%dT%H:%M:%S') 
                         for i in time]
                lower = bisect.bisect_left(dt,min(dt_in))
                upper = bisect.bisect_right(dt,max(dt_in))
                return kp[lower:upper]

#--------------------------------------------------------------------------

def make_time_labels(ndat, time_strings):
    '''
    Convert the time strings to 2-line versions so that
    the date and time do not cause significant ovlerlap 
    or vertical length on the x axis

    Input: 
        ndat: the number of indices in the current dataset
              (may wish to submit the times and divide on those)
        time_strings: a list of time strings for current data set
    Output:
        a set of five strings to be used as x-axis time labels
    '''

    from datetime import datetime

    tickind = ndat / 4 * np.arange(5)
    tickval = [datetime.strptime(i,'%Y-%m-%dT%H:%M:%S') 
               for i in time_strings[tickind]]
    tickname = [i for i in time_strings[tickind]]
    return [i.replace('T','\n') for i in tickname]

#--------------------------------------------------------------------------

def get_inst_obs_labels( kp, name ):
    '''
    Given parameter input in either string or integer format,
    identify the instrument name and observation type for use
    in accessing the relevant part of the data structure

    Input:
        kp: insitu data structure/dictionary
        name: string identifying a parameter
    Output:
        inst (1st arg): instrument identifier
        obs (2nd arg): observation type identifier
    N.B.: 'LPW.EWAVE_LOW_FREQ' would be returned as
          inst,obs = ['LPW','EWAVE_LOW_FREQ']
    '''

    from divide_lib_test import find_param_from_index as get_param

    # Need to ensure name is a string at this stage
    name = ('%s' % name)
    # Now, split at the dot (if it exists)
    tags = name.split('.')
    # And consider the various possibilities...
    if len(tags)==2:
        return tags
    elif len(tags)==1:
        try:
            int(tags[0])
            return (get_param(kp, tags[0])).split('.')
	except:
            print '*****ERROR*****'
            print '%s is an invalid parameter' % name
            print 'If only one value is provided, it must be an integer'
            return
    else:
        print '*****ERROR*****'
        print '%s is not a valid parameter' % name
        print 'because it has %1d elements' % len(tags)
        print 'Only 1 integer or string of form "a.b" are allowed.'
        print 'Please use .param_list attribute to find valid parameters'
        return

#--------------------------------------------------------------------------

def find_param_from_index( kp, index ):
    '''
    Given an integer index, find the name of the parameter
    Input: 
        insitu: the insitu data product
        index: the index of the desired parameter (integer type)
    Output:
        A string of form <instrument>.<observation>
        (e.g., LPW.EWAVE_LOW_FREQ)
    '''

    from divide_lib_test import param_list
    import sys
    import re

    index = '#%3d' % int(index)
    plist = param_list(kp)
    found = False
    for i in plist:
        if re.search(index, i):
            return i[5:] # clip the '#123 ' string
    if not found:
        print '*****ERROR*****'
        print '%s not a valid index.' % index
        print 'Use param_list to list options'
        return
#        sys.exit('In find_param_from_index: not found')

#--------------------------------------------------------------------------

def time_plot( kp, parameter=None, time=None, errors=None, 
               SamePlot=True, SubPlot=False ):
    '''
    Plot the provided data as a time series.
    For now, do not accept any error bar information.
    If time is not provided plot entire data set.
    SamePlot: if True, put all curves on same axes
              if False, generate new axes for each plot
    SubPlot: if True, stack plots with common x axis
             if False and nplots > 1, make several distinct plots
    '''

    import matplotlib.pyplot as plt
    from datetime import datetime

    # No need for get help routine: embedded in python
    # No need for tag parsing: python does this
    # No need for list call: that attribute has been provided
    # No need for range call: already provided

    # Check existence of parameter
    if parameter == None: 
        print "Must provide an index (or name) for param to be plotted."
        return
    # Store instrument and observation of parameter(s) in lists
    inst = []
    obs = []
    if type(parameter) is int or type(parameter) is str:
        a,b = get_inst_obs_labels( kp, parameter )
        inst.append(a)
        obs.append(b)
        nparam = 1
    else:
        nparam = len(parameter)
        for param in parameter:
            a,b = get_inst_obs_labels(kp,param)
            inst.append(a)
            obs.append(b)
    inst_obs = zip( inst, obs )

    # Check the time variable
    if time == None:
        istart, iend = 0,np.count_nonzero(kp.orbit)-1
    else:
        istart,iend = kp.range_select(time)

    # Possible hack: Make the time array
    t = [datetime.strptime(i,'%Y-%m-%dT%H:%M:%S') 
         for i in kp['time_string']]

    # Cycle through the parameters, plotting each according to
    #  the given keywords
    #
    iplot = 1 # subplot indexes on 1
    for inst,obs in inst_obs:
        #
        # First, generate the dependent array from data
        y = []
        index = 0
        for i in kp['time_string']:
            y.append(kp[inst][index][obs])
            index = index + 1

    # Generate the plot
        if iplot == 1 or not SamePlot: a = plt.figure()

    # If subplots, need to add a subplot
        if SubPlot: ax = a.add_subplot(nparam,1,iplot)

    # Now, generate the plot
        plt.plot(t,y,label=('%s.%s'%(inst,obs)))

    # If subplots, and not last one, suppress x-axis labels
        if SubPlot and iplot < nparam: ax.axes.xaxis.set_ticklabels([])

    # If last plot, get the five time strings for labels
        if iplot == nparam or not SamePlot:
            tickind = index / 4 * np.arange(5)

        # Set value of tickmarks
            xticknames = [datetime.strptime(i,'%Y-%m-%dT%H:%M:%S')
                          for i in kp['time_string'][tickind]]

        # Set text names of tick marks
            xticklab = make_time_labels( np.count_nonzero(kp), 
                                         kp['time_string'] )

        # Print ticknames labels at 90 degree rotation
            plt.xticks(xticknames, xticklab, rotation=90 )

        # Add useful axis labels
            plt.xlabel('%s' % 'time')

    # Add descriptive plot title
        if SamePlot: plt.title('%s.%s' % (inst,obs))
        if not SubPlot: plt.ylabel('%s.%s' % (inst,obs) )

    # Increment plot number 
        iplot = iplot + 1

    # Add legend if necessary
    if iplot > 1 and SamePlot and not SubPlot: plt.legend()

    # Return plot object?

#--------------------------------------------------------------------------

def alt_plot( kp, parameter=None, time=None, errors=None, 
               SamePlot=True, SubPlot=False ):
    '''
    Plot the provided data plotted against spacecraft altitude.
    For now, do not accept any error bar information.
    If time is not provided plot entire data set.
    SamePlot: if True, put all curves on same axes
              if False, generate new axes for each plot
    SubPlot: if True, stack plots with common x axis
             if False and nplots > 1, make several distinct plots
    '''

    import matplotlib.pyplot as plt
    from datetime import datetime

    # No need for get help routine: embedded in python
    # No need for tag parsing: python does this
    # No need for list call: that attribute has been provided
    # No need for range call: already provided

    # Check existence of parameter
    if parameter == None: 
        print "Must provide an index (or name) for param to be plotted."
        return
    # Store instrument and observation of parameter(s) in lists
    inst = []
    obs = []
    if type(parameter) is int or type(parameter) is str:
        a,b = get_inst_obs_labels( kp, parameter )
        inst.append(a)
        obs.append(b)
        nparam = 1
    else:
        nparam = len(parameter)
        for param in parameter:
            a,b = get_inst_obs_labels(kp,param)
            inst.append(a)
            obs.append(b)
    inst_obs = zip( inst, obs )

    # Check the time variable
    if time == None:
        istart, iend = 0,np.count_nonzero(kp.orbit)-1
    else:
        istart,iend = kp.range_select(time)

    # Generate the altitude array
    z = []
    index = 0
    for i in kp['time_string']:
        z.append(kp['spacecraft'][index]['altitude'])
        index = index + 1

    # Cycle through the parameters, plotting each according to
    #  the given keywords
    #
    iplot = 1 # subplot indexes on 1
    for inst,obs in inst_obs:
        #
        # First, generate the dependent array from data
        y = []
        index = 0
        for i in kp['time_string']:
            y.append(kp[inst][index][obs])
            index = index + 1

    # Generate the plot
        if iplot == 1 or not SamePlot: a = plt.figure()

    # If subplots, need to add a subplot
        if SubPlot: ax = a.add_subplot(1,nparam,iplot)

    # Now, generate the plot
        plt.plot(y,z,label=('%s.%s'%(inst,obs)))

    # If subplots, and not last one, suppress x-axis labels
        if SubPlot and iplot > 1 : 
            ax.axes.yaxis.set_ticklabels([])
        else:
            plt.ylabel('altitude[km]')
 
    # Add descriptive plot title
        if SubPlot or nparam == 1 or not SamePlot: 
            plt.title('%s.%s' % (inst,obs))
        else:
            plt.legend()

    # Increment plot number 
        iplot = iplot + 1

    # Return plot object?

#------------------------------------------------------------------------------

def read_insitu_file( filename, instruments = None, time=None ):
    '''
    Read in a given filename in situ file into a dictionary object
    Optional keywords maybe used to downselect instruments returned
     and the time windows.
    '''
    import pandas as pd
    import numpy as np
    import re
    import time
    from datetime import datetime

    # Determine number of header lines
    nheader = 0
    for line in open(filename):
        if line.startswith('#'):
            nheader = nheader+1
    #
    # Parse the header (still needs special case work)
    #
    ReadParamList = False
    index_list = []
    fin = open(filename)
    icol = -2 # Counting header lines detailing column names
    iname = 1 # for counting seven lines with name info
    ncol = -1 # Dummy value to allow reading of early headerlines?
    col_regex = '#\s(.{16}){%3d}' % ncol # needed for column names
    for iline in range(nheader):
        line = fin.readline()
        if re.search('Number of parameter columns',line): 
            ncol = int(re.split("\s{3}",line)[1])
            col_regex = '#\s(.{16}){%3d}' % ncol # needed for column names
        elif re.search('Line on which data begins',line): 
            nhead_test = int(re.split("\s{3}",line)[1])-1
        elif re.search('Number of lines',line): 
            ndata = int(re.split("\s{3}",line)[1])
        elif re.search('PARAMETER',line):
            ReadParamList = True
            ParamHead = iline
        elif ReadParamList:
            icol = icol + 1
            if icol > ncol: ReadParamList = False
        elif re.match(col_regex,line):
            # OK, verified match now get the values
            temp = re.findall('(.{16})',line[3:])
            if iname == 1: index = temp
            elif iname == 2: obs1 = temp
            elif iname == 3: obs2 = temp
            elif iname == 4: obs3 = temp
            elif iname == 5: inst = temp
            elif iname == 6: unit = temp
            elif iname == 7: FormatCode = temp
            else: 
                print 'More lines in data descriptor than expected.'
                print 'Line %d' % iline
            iname = iname + 1
        else:
            pass
    #
    # Generate the names list.
    # NB, there are special case redundancies in there
    # (e.g., LPW: Electron Density Quality (min and max))
    #
    First = True
    names = []
    for i,j,k in zip(obs1,obs2,obs3):
        combo_name = (' '.join([i.strip(),j.strip(),k.strip()])).strip()
        if re.match('(Electron|Spacecraft)(.+)Quality', combo_name):
            if First:
                combo_name = combo_name + ' Min'
                First = False
            else:
                combo_name = combo_name + ' Max'
                First = True
        names.append(combo_name)
    #
    # Now close the file and read the data section into a temporary DataFrame
    #
    fin.close()
    temp = pd.read_fwf(filename, skiprows=nheader, index_col=False, 
                       widths=[19]+ncol*[16], names = names)
    #
    # Assign the first-level only tags
    #
    Time = temp['Time']
    TimeUnix = [time.mktime(datetime.strptime(i,'%Y-%m-%dT%H:%M:%S')
                                             .timetuple()) 
                for i in temp['Time']]
    TimeUnix = pd.Series(TimeUnix) # convert into Series for consistency
    Orbit = temp['Orbit Number']
    IOflag = temp['Inbound Outbound Flag']
    #
    # Break up dictionary into instrument groups
    #
    LPWgroup, EUVgroup, SWEgroup, SWIgroup, STAgroup, SEPgroup, MAGgroup, \
    NGIgroup, APPgroup, SCgroup, SPICEgroup = [],[],[],[],[],[],[],[],[],[],[]
    First = True
    for i,j in zip(inst,names):
        if re.match('^LPW$',i.strip()):
            LPWgroup.append(j)
        elif re.match('^LPW-EUV$',i.strip()):
            EUVgroup.append(j)
        elif re.match('^SWEA$',i.strip()):
            SWEgroup.append(j)
        elif re.match('^SWIA$',i.strip()):
            SWIgroup.append(j)
        elif re.match('^STATIC$',i.strip()):
            STAgroup.append(j)
        elif re.match('^SEP$',i.strip()):
            SEPgroup.append(j)
        elif re.match('^MAG$',i.strip()):
            MAGgroup.append(j)
        elif re.match('^NGIMS$',i.strip()):
            NGIgroup.append(j)
        elif re.match('^SPICE$',i.strip()):
            # NB Need to split into APP and SPACECRAFT
            SPICEgroup.append(j) # keep for now for comparison
            if re.match('APP',j): 
                APPgroup.append(j)
            else: # Everything not APP is SC in SPICE
                # But do not include Orbit Num, or IO Flag
                # Could probably stand to clean this line up a bit
                if not re.match('(Orbit Number)|(Inbound Outbound Flag)',j):
                    SCgroup.append(j)
        else:
            pass
    for i in LPWgroup: print i
    #
    # Now assign the subSeries to the instruments
    #
    LPW=temp[LPWgroup]
    EUV=temp[EUVgroup]
    SWEA=temp[SWEgroup]
    SWIA=temp[SWIgroup]
    STATIC=temp[STAgroup]
    SEP=temp[SEPgroup]
    MAG=temp[MAGgroup]
    NGIMS=temp[NGIgroup]
    SPICE=temp[SPICEgroup] # needs to be split into APP and SPACECRAFT
    APP=temp[APPgroup]
    SPACECRAFT=temp[SCgroup]
    #
    # Clean up SPACECRAFT column names
    #
    newcol = []
    for oldcol in SPACECRAFT.columns:
        if oldcol.startswith('Spacecraft'):
            newcol.append(oldcol[len('Spacecraft '):])
        elif oldcol.startswith('Rot matrix MARS'):
            a,b = re.findall('\d{1}',oldcol)
            newcol.append('T%s%s' % (a,b))
        elif oldcol.startswith('Rot matrix SPC'):
            a,b = re.findall('\d{1}', oldcol)
            newcol.append('SPACECRAFT_T%s%s' % (a,b))
        else:
            newcol.append(oldcol)
    SPACECRAFT.columns = newcol

    # Others?

    # Do not forget to save units
    # Define the list of first level tag names
    tag_names = ['TimeString','Time','Orbit','IOflag',
                 'LPW','EUV','SWEA','SWIA','STATIC',
                 'SEP','MAG','NGIMS','APP','SPACECRAFT']
    # Define list of first level data structures
    data_tags = [Time, TimeUnix, Orbit, IOflag, 
                 LPW, EUV, SWEA, SWIA, STATIC, 
                 SEP, MAG, NGIMS, APP, SPACECRAFT]
    # return a dictionary made from tag_names and data_tags
    return dict( zip( tag_names, data_tags ) )
    # orig preserved for refernce
    #return dict(zip(['LPW','EUV','SWEA','SWIA','STATIC',
    #                 'SEP','MAG','NGIMS','SPICE'],
    #                [LPW,EUV,SWEA,SWIA,STATIC,SEP,MAG,NGIMS,SPICE]))