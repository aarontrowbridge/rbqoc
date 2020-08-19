"""
figures.jl
"""

using LaTeXStrings
using Printf
import Plots
using Statistics

WDIR = get(ENV, "ROBUST_QOC_PATH", "../../")
include(joinpath(WDIR, "src", "spin", "spin.jl"))

# Configure paths.
META_SAVE_PATH = joinpath(ENV["RBQOC_PATH"], "out", "spin")
EXPERIMENT_NAME = "figures"
SAVE_PATH = joinpath(META_SAVE_PATH, EXPERIMENT_NAME)

# Configure plotting.
ENV["GKSwstype"] = "nul"
Plots.gr()

# types
@enum PulseType begin
    qoc = 1
    analytic = 2
    derivative = 3
    sample = 4
end

const PT_STR = Dict(
    qoc => "QOC",
    analytic => "Analytic",
    sample => "Sample",
    derivative => "Derivative"
)

const PT_MARKER = Dict(
    sample => :circle,
    derivative => :square,
)

const PT_COLOR = Dict(
    analytic => :lightskyblue,
    qoc => :coral,
    sample => :green,
    derivative => :red,
)

const GT_LIST = [zpiby2, ypiby2, xpiby2]
const PT_LIST = [analytic, qoc]

# plotting constants
const ALPHA_POINT = 0.4
const MS_DATA = 4
const MS_POINT = 8
const FS_AXIS_LABELS = 12
const FS_AXIS_TICKS = 10
const DPI_FINAL = Integer(1e3)

# common dict keys
const SAVE_FILE_PATH_KEY = 1
const SAVE_TYPE_KEY = 2
const DATA_FILE_PATH_KEY = 3
const COLOR_KEY = 4
const ACORDS_KEY = 5
const MARKER_KEY = 6


### ALL ###
function plot_fidelity_by_gate_count(fidelitiess; inds=nothing, title="", ylims=(0, 1),
                                     yticks=(0:0.1:1), legend=nothing, yscale=:none,
                                     labels=nothing, colors=nothing, linestyles=nothing,
                                     xlims=nothing)
    plot_file_path = generate_save_file_path("png", EXPERIMENT_NAME, SAVE_PATH)
    fig = Plots.plot(dpi=DPI_FINAL, ylims=ylims, yticks=yticks, title=title,
                     legend=legend, yscale=yscale, xlims=xlims)
    gate_count = size(fidelitiess[1])[1] - 1
    gate_count_axis = Array(0:1:gate_count)
    if isnothing(inds)
        inds = 1:gate_count + 1
    end
    for (i, fidelities) in enumerate(fidelitiess)
        color = isnothing(colors) ? :auto : colors[i]
        label = isnothing(labels) ? nothing : labels[i]
        linestyle = isnothing(linestyles) ? :auto : linestyles[i]
        Plots.plot!(fig, gate_count_axis[inds], 1 .- fidelities[inds], label=label,
                    color=color, linestyle=linestyle)
    end
    Plots.ylabel!("Gate Error")
    Plots.xlabel!("Gate Count")
    plot_file_path = generate_save_file_path("png", EXPERIMENT_NAME, SAVE_PATH)
    Plots.savefig(fig, plot_file_path)
    return plot_file_path
end


### FIGURE 1 ###
const F1_GATE_COUNT = Integer(1.5e4)
F1_PULSE_DATA = Dict(
    zpiby2 => Dict(
        qoc => Dict(
            DATA_FILE_PATH_KEY => joinpath(META_SAVE_PATH, "spin15/00196_spin15.h5"),
            SAVE_FILE_PATH_KEY => joinpath(META_SAVE_PATH, "spin15/00194_spin15.h5"),
            SAVE_TYPE_KEY => jl,
        ),
        analytic => Dict(
            ACORDS_KEY => (0, 0.25),
            DATA_FILE_PATH_KEY => joinpath(META_SAVE_PATH, "spin14/00013_spin14.h5"),
            SAVE_FILE_PATH_KEY => joinpath(META_SAVE_PATH, "spin14/00000_spin14.h5"),
            SAVE_TYPE_KEY => py,
        ),
    ),
    ypiby2 => Dict(
        qoc => Dict(
            DATA_FILE_PATH_KEY => joinpath(META_SAVE_PATH, "spin15/00188_spin15.h5"),
            SAVE_FILE_PATH_KEY => joinpath(META_SAVE_PATH, "spin15/00185_spin15.h5"),
            SAVE_TYPE_KEY => jl,
        ),
        analytic => Dict(
            ACORDS_KEY => (0, 0.4),
            DATA_FILE_PATH_KEY => joinpath(META_SAVE_PATH, "spin14/00018_spin14.h5"),
            SAVE_FILE_PATH_KEY => joinpath(META_SAVE_PATH, "spin14/00003_spin14.h5"),
            SAVE_TYPE_KEY => py,
        )
    ),
    xpiby2 => Dict(
        qoc => Dict(
            DATA_FILE_PATH_KEY => joinpath(META_SAVE_PATH, "spin15/00176_spin15.h5"),
            SAVE_FILE_PATH_KEY => joinpath(META_SAVE_PATH, "spin15/00174_spin15.h5"),
            SAVE_TYPE_KEY => jl,
        ),
        analytic => Dict(
            ACORDS_KEY => (0, 0.5),
            DATA_FILE_PATH_KEY => joinpath(META_SAVE_PATH, "spin14/00022_spin14.h5"),
            SAVE_FILE_PATH_KEY => joinpath(META_SAVE_PATH, "spin14/00004_spin14.h5"),
            SAVE_TYPE_KEY => py,
        )
    ),
)


function make_figure1a()
    plot_file_path = generate_save_file_path("png", EXPERIMENT_NAME, SAVE_PATH)
    save_file_paths = []; save_types = []; labels = []; colors = [];
    subfigs = []
    for (i, gate_type) in enumerate(instances(GateType))
        subfig = Plots.plot()
        if i == 2
            Plots.ylabel!(subfig, "Amplitude (GHz)")
        elseif i == 3
            Plots.xlabel!(subfig, "Time (ns)")
        end
        text_ = GT_STR[gate_type]
        (ax, ay) = F1_PULSE_DATA[gate_type][analytic][ACORDS_KEY]
        Plots.annotate!(subfig, ax, ay, text(text_, 10))
        for pulse_type in PT_LIST
            if pulse_type == analytic
                linestyle = :solid
            elseif pulse_type == qoc
                linestyle = :solid
            end
            data = F1_PULSE_DATA[gate_type][pulse_type]
            color = PT_COLOR[pulse_type]
            label = "$(GT_STR[gate_type]) $(PT_STR[pulse_type])"
            save_file_path = data[SAVE_FILE_PATH_KEY]
            save_type = data[SAVE_TYPE_KEY]
            (controls, evolution_time) = grab_controls(save_file_path; save_type=save_type)
            (control_eval_count, control_count) = size(controls)
            control_eval_times = Array(1:1:control_eval_count) * DT_PREF
            Plots.plot!(subfig, control_eval_times, controls[:,1], color=color, label=nothing,
                        linestyle=linestyle)
        end
        push!(subfigs, subfig)
    end
    layout = @layout [a; b; c]
    fig = Plots.plot(subfigs[1], subfigs[2], subfigs[3], layout=layout, dpi=DPI_FINAL,
                     tickfontsize=FS_AXIS_TICKS, guidefontsize=FS_AXIS_LABELS)
    Plots.savefig(fig, plot_file_path)
    println("Saved Figure1a to $(plot_file_path)")
end


const GT_LS_1B = Dict(
    zpiby2 => :solid,
    ypiby2 => :dash,
    xpiby2 => :dashdot,
)

function make_figure1b()
    # TODO: get data
    for gate_type in keys(F1_PULSE_DATA)
        for pulse_type in keys(F1_PULSE_DATA[gate_type])
            pulse_data = F1_PULSE_DATA[gate_type][pulse_type]
            if !(DATA_FILE_PATH_KEY in keys(pulse_data))
                # get data_file_path and write it to pulse data here
                data_file_path = nothing
            end
        end
    end
    
    # plot
    fidelitiess = []; labels = []; colors = []; linestyles = []
    for gate_type in GT_LIST
        for pulse_type in keys(F1_PULSE_DATA[gate_type])
            pulse_data = F1_PULSE_DATA[gate_type][pulse_type]
            (fidelities,) = h5open(pulse_data[DATA_FILE_PATH_KEY], "r") do data_file
                fidelities = read(data_file, "fidelities")
                return (fidelities,)
            end
            color = PT_COLOR[pulse_type]
            label = "$(GT_STR[gate_type]) $(PT_STR[pulse_type])"
            linestyle = GT_LS_1B[gate_type]
            push!(fidelitiess, fidelities)
            push!(labels, label)
            push!(colors, color)
            push!(linestyles, linestyle)
        end
    end
    plot_file_path = plot_fidelity_by_gate_count(
        fidelitiess; ylims=(0, 0.05), yticks=0:0.01:0.05, legend=:topleft,
        labels=labels, colors=colors, linestyles=linestyles,
        xlims=(0, 1700)
    )
    println("Plotted Figure1b to $(plot_file_path)")
end


const F1C_SAMPLE_LEN = Integer(1e4)
const GT_MK_1C = Dict(
    zpiby2 => :diamond,
    ypiby2 => :square,
    xpiby2 => :utriangle,
)
const MS_F1C = 6
const ALPHA_F1C = 1.

function make_figure1c()
    # Collect data and plot.
    max_amp = MAX_CONTROL_NORM_0
    amps_fit = Array(range(0, stop=max_amp, length=F1C_SAMPLE_LEN))
    t1s_fit =  map(amp_t1_spline_cubic, amps_fit)
    amps_data = -1 .* map(fbfq_amp_lo, FBFQ_ARRAY)
    t1s_data = T1_ARRAY
    fig = Plots.plot(dpi=DPI_FINAL, legend=:bottomright, yscale=:log10)
    Plots.plot!(amps_fit, t1s_fit, label="Fit", color=:mediumaquamarine)
    Plots.scatter!(amps_data, t1s_data, label="Data", marker=(:circle, MS_DATA),
                   color=:mediumorchid)
    for gate_type in GT_LIST
        for pulse_type in keys(F1_PULSE_DATA[gate_type])
            pulse_data = F1_PULSE_DATA[gate_type][pulse_type]
            (controls, _) = grab_controls(
                pulse_data[SAVE_FILE_PATH_KEY];
                save_type=pulse_data[SAVE_TYPE_KEY]
            )
            avg_amp = mean(map(abs, controls[:,1]))
            avg_t1 = amp_t1_spline_cubic(avg_amp)
            avg_label = "$(GT_STR[gate_type]) $(PT_STR[pulse_type])"
            avg_color = PT_COLOR[pulse_type]
            marker = GT_MK_1C[gate_type]
            Plots.plot!([avg_amp], [avg_t1], label=avg_label,
                        marker=(marker, MS_F1C), color=avg_color, alpha=ALPHA_F1C)
        end
    end
    Plots.xlabel!("Avg. Amplitude (GHz)")
    Plots.ylabel!(latexstring("\$T_1 \\ \\textrm{(ns)}\$"))
    Plots.xlims!((-0.02, max_amp))
    plot_file_path = generate_save_file_path("png", EXPERIMENT_NAME, SAVE_PATH)
    Plots.savefig(fig, plot_file_path)
    println("Plotted Figure1c to $(plot_file_path)")
end


### FIGURE 2 ###
F2_PULSE_DATA = Dict(
    derivative => Dict(
        SAVE_FILE_PATH_KEY => joinpath(META_SAVE_PATH, "spin11/00091_spin11.h5"),
        SAVE_TYPE_KEY => jl,
        DATA_FILE_PATH_KEY => joinpath(META_SAVE_PATH, "spin11/00092_spin11.h5")
    ),
    sample => Dict(
        SAVE_FILE_PATH_KEY => joinpath(META_SAVE_PATH, "spin12/00132_spin12.h5"),
        SAVE_TYPE_KEY => jl,
        DATA_FILE_PATH_KEY => joinpath(META_SAVE_PATH, "spin12/00200_spin12.h5")
    ),
    analytic => Dict(
        SAVE_FILE_PATH_KEY => joinpath(META_SAVE_PATH, "spin14/00004_spin14.h5"),
        SAVE_TYPE_KEY => py,
        DATA_FILE_PATH_KEY => joinpath(META_SAVE_PATH, "spin14/00028_spin14.h5")
    ),
)


"""
Show the pulses.
"""
function make_figure2a()
    return
end


const F2B_TRIAL_COUNT = Integer(1e3)
const F2B_FQ_DEV = 1e-1
"""
Show gate error vs. detuning
"""
function make_figure2b()
    # sample detunings
    fq_devs = Array(range(-F2B_FQ_DEV, stop=F2B_FQ_DEV, length=F2B_TRIAL_COUNT))
    fqs = (fq_devs .* FQ) .+ FQ
    negi_h0s = [NEGI_H0_ISO * fq for fq in fqs]

    # sweep
    gate_type = xpiby2
    for pulse_type in keys(F2_PULSE_DATA)
        if !(DATA_FILE_PATH_KEY in keys(F2_PULSE_DATA[pulse_type]))
            save_file_path = F2_PULSE_DATA[pulse_type][SAVE_FILE_PATH_KEY]
            save_type = F2_PULSE_DATA[pulse_type][SAVE_TYPE_KEY]
            data_file_path = run_sim_h0sweep_deqjl(gate_type, negi_h0s; save_file_path=save_file_path,
                                                   save_type=save_type)
            h5open(data_file_path, "r+") do data_file
                write(data_file, "fqs", fqs)
                write(data_file, "pulse_type", Integer(pulse_type))
            end
            F2_PULSE_DATA[pulse_type][DATA_FILE_PATH_KEY] = data_file_path
        end
    end

    # plot
    fig = Plots.plot(dpi=DPI, yticks=[0.985, 0.99, 0.995, 1.00], ylim=(0.985, 1.0),
                     xlim=(minimum(fq_devs), maximum(fq_devs)))
    for pulse_type in keys(F2_PULSE_DATA)
        pulse_data = F2_PULSE_DATA[pulse_type]
        label = "$(PT_STR[pulse_type])"
        color = PT_COLOR[pulse_type]
        data_file_path = pulse_data[DATA_FILE_PATH_KEY]
        (fidelities,) = h5open(data_file_path, "r") do data_file
            fidelities = read(data_file, "fidelities")
            return (fidelities,)
        end
        Plots.plot!(fig, fq_devs, fidelities, label=label, color=color)
                    
    end
    plot_file_path = generate_save_file_path("png", EXPERIMENT_NAME, SAVE_PATH)
    Plots.xlabel!(L"$\delta \omega_{q} / \omega_{q}$")
    Plots.ylabel!("Fidelity")
    Plots.savefig(fig, plot_file_path)
    println("Plotted Figure2b to $(plot_file_path)")
end

F2C_GATE_TIMES = [60, 70, 80, 90, 100, 110, 120]
F2C_PULSE_DATA = Dict(
    sample => Dict(
        F2C_GATE_TIMES[1] => Dict(
            SAVE_FILE_PATH_KEY => joinpath(META_SAVE_PATH, "spin12/00138_spin12.h5"),
            SAVE_TYPE_KEY => jl,
        ),
        F2C_GATE_TIMES[2] => Dict(
            SAVE_FILE_PATH_KEY => joinpath(META_SAVE_PATH, "spin12/00145_spin12.h5"),
            SAVE_TYPE_KEY => jl,
        ),
        F2C_GATE_TIMES[3] => Dict(
            SAVE_FILE_PATH_KEY => joinpath(META_SAVE_PATH, "spin12/00147_spin12.h5"),
            SAVE_TYPE_KEY => jl,
        ),
        F2C_GATE_TIMES[4] => Dict(
            SAVE_FILE_PATH_KEY => joinpath(META_SAVE_PATH, "spin12/00148_spin12.h5"),
            SAVE_TYPE_KEY => jl,
        ),
        F2C_GATE_TIMES[5] => Dict(
            SAVE_FILE_PATH_KEY => joinpath(META_SAVE_PATH, "spin12/00150_spin12.h5"),
            SAVE_TYPE_KEY => jl,
        ),
        F2C_GATE_TIMES[6] => Dict(
            SAVE_FILE_PATH_KEY => joinpath(META_SAVE_PATH, "spin12/00151_spin12.h5"),
            SAVE_TYPE_KEY => jl,
        ),
        F2C_GATE_TIMES[7] => Dict(
            SAVE_FILE_PATH_KEY => joinpath(META_SAVE_PATH, "spin12/00153_spin12.h5"),
            SAVE_TYPE_KEY => jl,
        ),
    ),
    # derivative => Dict(
    # ),
)
function make_figure2c()
    gate_type = xpiby2
    
    # get data and plot
    fig = Plots.plot(dpi=DPI_FINAL, legend=:bottomright)
    for pulse_type in keys(F2C_PULSE_DATA)
        label = "$(PT_STR[pulse_type])"
        color = PT_COLOR[pulse_type]
        marker = PT_MARKER[pulse_type]
        for (i, gate_time) in enumerate(F2C_GATE_TIMES)
            # compute
            data = F2C_PULSE_DATA[pulse_type][gate_time]
            save_file_path = data[SAVE_FILE_PATH_KEY]
            save_type = data[SAVE_TYPE_KEY]
            data_file_path1 = run_sim_deqjl(
                1, gate_type; save_file_path=save_file_path,
                save_type=save_type, dynamics_type=schroed, dt=1e-3,
                negi_h0=S1FQ_NEGI_H0_ISO,
            )
            data_file_path2 = run_sim_deqjl(
                1, gate_type; save_file_path=save_file_path,
                save_type=save_type, dynamics_type=schroed, dt=1e-3,
                negi_h0=S2FQ_NEGI_H0_ISO,
            )
            (fidelity1,) = h5open(data_file_path1, "r") do data_file1
                fidelity1 = read(data_file1, "fidelities")[end]
                return (fidelity1,)
            end
            (fidelity2,) = h5open(data_file_path2, "r") do data_file2
                fidelity2 = read(data_file2, "fidelities")[end]
                return (fidelity2,)
            end
            fidelity = mean([fidelity1, fidelity2])

            # plot
            label = i == 1 ? label : nothing
            Plots.scatter!(fig, [gate_time], [fidelity], label=label, color=color,
                           marker=(marker, MS_DATA))
        end
    end
    plot_file_path = generate_save_file_path("png", EXPERIMENT_NAME, SAVE_PATH)
    Plots.savefig(fig, plot_file_path)
    println("Plotted Figure2c to $(plot_file_path)")
end


### FIGURE 3 ###
F3_PULSE_DATA = Dict(
    derivative => Dict(
        SAVE_FILE_PATH_KEY => joinpath(META_SAVE_PATH, ""),
        SAVE_TYPE_KEY => jl,
        COLOR_KEY => :red,
        DATA_FILE_PATH_KEY => joinpath(META_SAVE_PATH, "")
    ),
    sample => Dict(
        SAVE_FILE_PATH_KEY => joinpath(META_SAVE_PATH, ""),
        SAVE_TYPE_KEY => jl,
        COLOR_KEY => :green
    ),
    analytic => Dict(
        SAVE_FILE_PATH_KEY => joinpath(META_SAVE_PATH, ""),
        SAVE_TYPE_KEY => py,
        COLOR_KEY => :lightskyblue,
        DATA_FILE_PATH_KEY => joinpath(META_SAVE_PATH, ""),
    ),
)

F3A_GATE_COUNT = Integer(1700)
F3A_DT = 1e-3
function make_figure3a()
    # compute
    gate_type = ypiby2
    dynamics_type = lindbladcfn
    for pulse_type in keys(F3_PULSE_DATA)
        pulse_data = F3_PULSE_DATA[pulse_type]
        if isnothing(pulse_data[DATA_FILE_PATH_KEY])
            save_file_path = pulse_data[SAVE_FILE_PATH_KEY]
            save_type = pulse_data[SAVE_TYPE_KEY]
            data_file_path = run_sim_deqjl(
                F3A_GATE_COUNT, gate_type; save_file_path=save_file_path,
                save_type=save_type, dynamics_type=dynamics_type, dt=F3A_DT
            )
            pulse_data[DATA_FILE_PATH_KEY] = data_file_path
        end
    end
    
    # plot
    colors = []; fidelitiess = []; labels = []
    for pulse_type in keys(F3_PULSE_DATA)
        (fidelities,) = h5open(F3_PULSE_DATA[pulse_type][SAVE_FILE_PATH_KEY], "r") do save_file
            fidelities = read(save_file, "fidelities")
            return (fidelities,)
        end
        color = F3_PULSE_DATA[pulse_type][COLOR_KEY]
        label = "$(PT_STR[pulse_type])"
        push!(colors, color)
        push!(fideltiess, fidelities)
        push!(labels, label)
    end
    plot_file_path = plot_fidelity_by_gate_count(fidelitiess; labels=labels, colors=colors)
    println("Plotted Figure3a to $(plot_file_path)")
end
