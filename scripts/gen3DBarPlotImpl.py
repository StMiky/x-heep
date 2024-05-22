import argparse
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from mpl_toolkits.mplot3d import Axes3D
from scipy.interpolate import griddata

def parse_args():
    parser = argparse.ArgumentParser(description='Generate 2D bar plot of implementation IPC/Latency')
    parser.add_argument('--csv', type=str, help='Path to the results of the simulation', required=True)
    parser.add_argument('--output', type=str, help='name of plot', required=True)

    parser.add_argument('--type', type=str, choices=["PIPELINE", "ITERATIVE"], required=True, default="PIPELINE", help='Type of implementation')
    return parser.parse_args()


def main():
    # Parse the arguments
    args = parse_args()

    # Read the CSV file
    df = pd.read_csv(args.csv)

    df = df.sort_values(by=['Latency'], ascending=False)

    # Create the 3D bar plot
    fig = plt.figure()
    ax = fig.add_subplot(111, projection='3d')

    # Group by type
    grouped = df.groupby('Type')

    # Plot on the 3D bar plot
    # The x-axis is the latency
    # the y-axis is the NBI
    # The z-axis is the IPC

    shiftup = 0.0

    # Surface plot
    # for name, group in grouped:
    #     if (name == args.type):
    #         ax.plot_trisurf(group['Latency'], group['NBI'], group['IPC'], cmap=plt.cm.viridis, label=name)

    # Select those belonging to type args.type
    # for name, group in grouped:
    #     if (name == args.type):
    #         # Group by latency
    #         for latency, latency_group in group.groupby('Latency'):
    #             # Group by NBI
    #             for nbi, nbi_group in latency_group.groupby('NBI'):
    #                 ax.bar3d(nbi_group['Latency'], nbi_group['NBI'], shiftup, 0.5, 0.5, nbi_group['IPC']-shiftup, label=name, shade=True, color=plt.cm.viridis(nbi_group['IPC']))
    
    # Create grid data for interpolation
    filtered_df = df[df['Type'] == args.type]
    latencies = np.linspace(filtered_df['Latency'].min(), filtered_df['Latency'].max(), 100)
    nbis = np.linspace(filtered_df['NBI'].min(), filtered_df['NBI'].max(), 100)
    latencies_grid, nbis_grid = np.meshgrid(latencies, nbis)

    # Interpolate IPC values on the grid
    ipc_grid = griddata((filtered_df['Latency'], filtered_df['NBI']), filtered_df['IPC'], (latencies_grid, nbis_grid), method='cubic')

    # Plot the interpolated surface
    surf = ax.plot_surface(latencies_grid, nbis_grid, ipc_grid, cmap=plt.cm.coolwarm, edgecolor='none', vmin=0, vmax=1)

    # Plot an interpolated surface
    
    
    
    # # Add spacing between the bars and use a different color scheme
    ax.view_init(elev=20, azim=-30)


    # Set the labels
    ax.set_xlabel('Latency')
    ax.set_ylabel('NBI')
    ax.set_zlabel('IPC')

    # Set limits
    ax.set_zlim(shiftup,1)

    # Set the title
    plt.title(f"IPC vs Latency and NBI for {args.type} implementation")

    # Save the plot
    plt.savefig(f"{args.output}", dpi=300)


if __name__ == '__main__':
    main()

